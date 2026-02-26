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

  static const String _key = 'theme_mode';

  @override
  Future<ThemeSettingsEntity> getThemeSettings() async {
    final stored = await dao.getValue(_key);
    if (stored == null) return ThemeSettingsEntity.defaults();

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
        return ThemeSettingsEntity.fromJson(decoded);
      }
      if (decoded is String) {
        return ThemeSettingsEntity(mode: _normalizeMode(decoded));
      }
    } catch (_) {
      // 2) JSON 解析失败，按明文解析
    }

    return ThemeSettingsEntity(mode: _normalizeMode(candidate));
  }

  @override
  Future<void> saveThemeSettings(ThemeSettingsEntity settings) async {
    final json = jsonEncode(settings.toJson());
    final encrypted = await _crypto.encrypt(json);
    await dao.upsertValue(_key, encrypted);

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
      data: {'theme_mode': settings.mode},
      timestampMs: ts,
    );
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
