/// 文件用途：番茄钟配置仓储实现（PomodoroSettingsRepositoryImpl），支持加密存储。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

import 'dart:convert';

import '../../domain/entities/pomodoro_settings.dart';
import '../../domain/repositories/pomodoro_settings_repository.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../infrastructure/storage/settings_crypto.dart';
import '../database/daos/settings_dao.dart';

/// 番茄钟配置仓储实现。
///
/// 说明：
/// - 复用 settings 表和 SettingsCrypto，避免引入独立配置存储
/// - 当前配置仅本机生效，不写入同步日志
class PomodoroSettingsRepositoryImpl implements PomodoroSettingsRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 设置 DAO
  /// - [secureStorageService] 安全存储服务
  PomodoroSettingsRepositoryImpl({
    required this.dao,
    required SecureStorageService secureStorageService,
  }) : _crypto = SettingsCrypto(secureStorageService: secureStorageService);

  final SettingsDao dao;
  final SettingsCrypto _crypto;

  static const String _keyWorkMinutes = 'pomodoro_work_minutes';
  static const String _keyShortBreakMinutes = 'pomodoro_short_break_minutes';
  static const String _keyLongBreakMinutes = 'pomodoro_long_break_minutes';
  static const String _keyLongBreakInterval = 'pomodoro_long_break_interval';

  @override
  Future<PomodoroSettingsEntity> getSettings() async {
    final defaults = PomodoroSettingsEntity.defaults;
    return PomodoroSettingsEntity(
      workMinutes: await _getIntOrDefault(_keyWorkMinutes, defaults.workMinutes),
      shortBreakMinutes: await _getIntOrDefault(
        _keyShortBreakMinutes,
        defaults.shortBreakMinutes,
      ),
      longBreakMinutes: await _getIntOrDefault(
        _keyLongBreakMinutes,
        defaults.longBreakMinutes,
      ),
      longBreakInterval: await _getIntOrDefault(
        _keyLongBreakInterval,
        defaults.longBreakInterval,
      ),
    );
  }

  @override
  Future<void> saveSettings(PomodoroSettingsEntity settings) async {
    // 关键逻辑：保存前兜底裁剪最小值，避免脏配置导致计时器出现 0 或负数。
    final normalized = PomodoroSettingsEntity(
      workMinutes: settings.workMinutes.clamp(1, 180).toInt(),
      shortBreakMinutes: settings.shortBreakMinutes.clamp(1, 60).toInt(),
      longBreakMinutes: settings.longBreakMinutes.clamp(1, 120).toInt(),
      longBreakInterval: settings.longBreakInterval.clamp(1, 12).toInt(),
    );

    await dao.upsertValues({
      _keyWorkMinutes: await _crypto.encrypt(jsonEncode(normalized.workMinutes)),
      _keyShortBreakMinutes: await _crypto.encrypt(
        jsonEncode(normalized.shortBreakMinutes),
      ),
      _keyLongBreakMinutes: await _crypto.encrypt(
        jsonEncode(normalized.longBreakMinutes),
      ),
      _keyLongBreakInterval: await _crypto.encrypt(
        jsonEncode(normalized.longBreakInterval),
      ),
    });
  }

  /// 读取一个 int 设置，读取失败时返回默认值。
  Future<int> _getIntOrDefault(String key, int defaultValue) async {
    try {
      final stored = await dao.getValue(key);
      if (stored == null) return defaultValue;
      final decrypted = await _crypto.decrypt(stored);
      final decoded = jsonDecode(decrypted);
      if (decoded is int) return decoded;
      if (decoded is num) return decoded.toInt();
      return int.tryParse(decoded.toString()) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }
}
