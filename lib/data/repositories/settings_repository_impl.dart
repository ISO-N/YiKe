/// 文件用途：应用设置仓储实现（SettingsRepositoryImpl），支持对设置项进行加密存储。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../infrastructure/storage/settings_crypto.dart';
import '../database/daos/settings_dao.dart';

/// 应用设置仓储实现。
class SettingsRepositoryImpl implements SettingsRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] SettingsDao
  /// - [secureStorageService] 安全存储服务（用于保存加密密钥）
  /// 异常：无。
  SettingsRepositoryImpl({
    required this.dao,
    required this.secureStorageService,
  }) : _crypto = SettingsCrypto(secureStorageService: secureStorageService);

  final SettingsDao dao;
  final SecureStorageService secureStorageService;
  final SettingsCrypto _crypto;

  // 预设设置项 Key（与 TDD 一致）。
  static const String keyReminderTime = 'reminder_time';
  static const String keyDndStart = 'do_not_disturb_start';
  static const String keyDndEnd = 'do_not_disturb_end';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyNotificationPermissionGuideDismissed =
      'notification_permission_guide_dismissed';

  // v1.0 MVP 扩展：用于后台防重复发送通知。
  static const String keyLastNotifiedDate = 'last_notified_date';

  @override
  Future<AppSettingsEntity> getSettings() async {
    final reminderTime =
        await _getString(keyReminderTime) ??
        AppSettingsEntity.defaults.reminderTime;
    final dndStart =
        await _getString(keyDndStart) ??
        AppSettingsEntity.defaults.doNotDisturbStart;
    final dndEnd =
        await _getString(keyDndEnd) ??
        AppSettingsEntity.defaults.doNotDisturbEnd;
    final notificationsEnabled =
        await _getBool(keyNotificationsEnabled) ??
        AppSettingsEntity.defaults.notificationsEnabled;
    final guideDismissed =
        await _getBool(keyNotificationPermissionGuideDismissed) ??
        AppSettingsEntity.defaults.notificationPermissionGuideDismissed;
    final lastNotifiedDate = await _getString(keyLastNotifiedDate);

    return AppSettingsEntity(
      reminderTime: reminderTime,
      doNotDisturbStart: dndStart,
      doNotDisturbEnd: dndEnd,
      notificationsEnabled: notificationsEnabled,
      notificationPermissionGuideDismissed: guideDismissed,
      lastNotifiedDate: lastNotifiedDate,
    );
  }

  @override
  Future<void> saveSettings(AppSettingsEntity settings) async {
    await dao.upsertValues({
      keyReminderTime: await _crypto.encrypt(jsonEncode(settings.reminderTime)),
      keyDndStart: await _crypto.encrypt(
        jsonEncode(settings.doNotDisturbStart),
      ),
      keyDndEnd: await _crypto.encrypt(jsonEncode(settings.doNotDisturbEnd)),
      keyNotificationsEnabled: await _crypto.encrypt(
        jsonEncode(settings.notificationsEnabled),
      ),
      keyNotificationPermissionGuideDismissed: await _crypto.encrypt(
        jsonEncode(settings.notificationPermissionGuideDismissed),
      ),
      if (settings.lastNotifiedDate != null)
        keyLastNotifiedDate: await _crypto.encrypt(
          jsonEncode(settings.lastNotifiedDate),
        ),
    });
  }

  Future<String?> _getString(String key) async {
    final stored = await dao.getValue(key);
    if (stored == null) return null;
    final decrypted = await _crypto.decrypt(stored);
    final decoded = jsonDecode(decrypted);
    return decoded is String ? decoded : decoded?.toString();
  }

  Future<bool?> _getBool(String key) async {
    final stored = await dao.getValue(key);
    if (stored == null) return null;
    final decrypted = await _crypto.decrypt(stored);
    final decoded = jsonDecode(decrypted);
    return decoded is bool ? decoded : null;
  }
}
