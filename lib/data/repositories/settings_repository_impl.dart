/// 文件用途：应用设置仓储实现（SettingsRepositoryImpl），支持对设置项进行加密存储。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/review_interval_config.dart';
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

  // v2.1：复习间隔配置。
  static const String keyReviewIntervals = 'review_intervals';

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

  @override
  Future<List<ReviewIntervalConfigEntity>> getReviewIntervalConfigs() async {
    final decoded = await _getDecoded(keyReviewIntervals);
    final fallback = _defaultReviewIntervals();
    if (decoded == null) return fallback;

    try {
      if (decoded is! List) return fallback;
      final result = <ReviewIntervalConfigEntity>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final round = item['round'];
        final interval = item['interval'];
        final enabled = item['enabled'];
        if (round is! int || interval is! int || enabled is! bool) continue;
        // 关键逻辑：对边界值做保护，避免脏数据导致录入崩溃。
        if (round < 1 || round > 5) continue;
        if (interval < 1) continue;
        result.add(
          ReviewIntervalConfigEntity(
            round: round,
            intervalDays: interval,
            enabled: enabled,
          ),
        );
      }

      // 至少保留一轮复习，否则回退默认配置。
      final hasEnabled = result.any((e) => e.enabled);
      if (!hasEnabled) return fallback;

      // 以 round 排序，便于 UI 展示稳定。
      result.sort((a, b) => a.round.compareTo(b.round));
      if (result.isEmpty) return fallback;
      return result;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<void> saveReviewIntervalConfigs(
    List<ReviewIntervalConfigEntity> configs,
  ) async {
    // 保护：避免写入空配置导致后续生成任务异常。
    final next = configs.isEmpty ? _defaultReviewIntervals() : configs;

    final hasEnabled = next.any((e) => e.enabled);
    if (!hasEnabled) {
      throw ArgumentError('至少保留一轮复习');
    }

    final normalized = next
        .map(
          (e) => {
            'round': e.round,
            'interval': e.intervalDays,
            'enabled': e.enabled,
          },
        )
        .toList();

    await dao.upsertValue(
      keyReviewIntervals,
      await _crypto.encrypt(jsonEncode(normalized)),
    );
  }

  List<ReviewIntervalConfigEntity> _defaultReviewIntervals() {
    const defaults = [1, 2, 4, 7, 15];
    return List<ReviewIntervalConfigEntity>.generate(
      defaults.length,
      (index) => ReviewIntervalConfigEntity(
        round: index + 1,
        intervalDays: defaults[index],
        enabled: true,
      ),
    );
  }

  Future<dynamic> _getDecoded(String key) async {
    final stored = await dao.getValue(key);
    if (stored == null) return null;
    final decrypted = await _crypto.decrypt(stored);
    return jsonDecode(decrypted);
  }

  Future<String?> _getString(String key) async {
    final decoded = await _getDecoded(key);
    if (decoded == null) return null;
    return decoded is String ? decoded : decoded?.toString();
  }

  Future<bool?> _getBool(String key) async {
    final decoded = await _getDecoded(key);
    if (decoded == null) return null;
    return decoded is bool ? decoded : null;
  }
}
