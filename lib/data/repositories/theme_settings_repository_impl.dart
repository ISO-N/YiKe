/// 文件用途：主题设置仓储实现（ThemeSettingsRepositoryImpl），支持加密存储。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';

import '../../domain/entities/theme_settings.dart';
import '../../domain/repositories/theme_settings_repository.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../infrastructure/storage/settings_crypto.dart';
import '../database/daos/settings_dao.dart';
import '../sync/sync_log_writer.dart';

/// 主题设置仓储实现。
///
/// 存储策略：
/// - key: 'theme_mode'
/// - value: 加密的 JSON 字符串：'{"mode":"system|light|dark"}'
/// - 与现有设置项保持一致（加密 + JSON 包装）
///
/// 扩展（v1.4.0 用户体验改进）：
/// - key: 'theme_seed_color'，value: 加密 JSON 字符串（HEX："#RRGGBB"）
/// - key: 'theme_amoled'，value: 加密 JSON 字符串（bool）
///
/// 读取兼容策略：
/// - 若解密或 JSON 解析失败，尝试将原始值视为明文 'system'|'light'|'dark'
/// - 仍失败则回退默认值 system
class ThemeSettingsRepositoryImpl implements ThemeSettingsRepository {
  ThemeSettingsRepositoryImpl({
    required this.dao,
    required this.secureStorageService,
    SyncLogWriter? syncLogWriter,
  }) : _crypto = SettingsCrypto(secureStorageService: secureStorageService),
       _sync = syncLogWriter;

  final SettingsDao dao;
  final SecureStorageService secureStorageService;
  final SettingsCrypto _crypto;
  final SyncLogWriter? _sync;

  static const String _keyMode = 'theme_mode';
  static const String _keySeedColor = 'theme_seed_color';
  static const String _keyAmoled = 'theme_amoled';

  @override
  Future<ThemeSettingsEntity> getThemeSettings() async {
    final defaults = ThemeSettingsEntity.defaults();

    final storedMode = await dao.getValue(_keyMode);
    final mode = storedMode == null
        ? defaults.mode
        : await _readModeWithCompat(storedMode);

    final seedColorHex = await _getString(_keySeedColor) ?? defaults.seedColorHex;
    final amoled = await _getBool(_keyAmoled) ?? defaults.amoled;

    return ThemeSettingsEntity(
      mode: _normalizeMode(mode),
      seedColorHex: seedColorHex,
      amoled: amoled,
    );
  }

  @override
  Future<void> saveThemeSettings(ThemeSettingsEntity settings) async {
    // 1) 主题模式：保持历史兼容的 JSON 包装格式（{"mode":...}）。
    final modeJson = jsonEncode({'mode': settings.mode});
    final modeEncrypted = await _crypto.encrypt(modeJson);
    await dao.upsertValue(_keyMode, modeEncrypted);

    // 2) 主题种子色与 AMOLED：按独立 key 保存，便于同步与回滚开关。
    await dao.upsertValue(
      _keySeedColor,
      await _crypto.encrypt(jsonEncode(settings.seedColorHex)),
    );
    await dao.upsertValue(
      _keyAmoled,
      await _crypto.encrypt(jsonEncode(settings.amoled)),
    );

    // v3.0（F12）：记录主题模式变更（以 settings_bundle 事件同步）。
    final sync = _sync;
    if (sync == null) return;

    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'settings_bundle',
      localEntityId: 1,
      appliedAtMs: ts,
    );
    await sync.logEvent(
      origin: origin,
      entityType: 'settings_bundle',
      operation: 'update',
      data: {
        'theme_mode': settings.mode,
        'theme_seed_color': settings.seedColorHex,
        'theme_amoled': settings.amoled,
      },
      timestampMs: ts,
    );
  }

  Future<String> _readModeWithCompat(String stored) async {
    String candidate;
    try {
      candidate = await _crypto.decrypt(stored);
    } catch (_) {
      // 解密失败时，回退尝试按明文解析（兼容灰度/脏数据）。
      candidate = stored;
    }

    // 1) 优先按 JSON 解析：{"mode":"system|light|dark"}
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) {
        return decoded['mode'] as String? ?? 'system';
      }
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // 2) JSON 解析失败，按明文解析
    }

    return candidate;
  }

  Future<dynamic> _getDecoded(String key) async {
    final stored = await dao.getValue(key);
    if (stored == null) return null;
    try {
      final decrypted = await _crypto.decrypt(stored);
      return jsonDecode(decrypted);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getString(String key) async {
    final decoded = await _getDecoded(key);
    if (decoded == null) return null;
    return decoded is String ? decoded : decoded.toString();
  }

  Future<bool?> _getBool(String key) async {
    final decoded = await _getDecoded(key);
    if (decoded == null) return null;
    return decoded is bool ? decoded : null;
  }

  String _normalizeMode(String raw) {
    switch (raw) {
      case 'system':
      case 'light':
      case 'dark':
        return raw;
      default:
        return 'system';
    }
  }
}
