/// 文件用途：学习目标设置仓储实现（GoalSettingsRepositoryImpl），支持加密存储与同步日志写入。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'dart:convert';

import '../../domain/entities/goal_settings.dart';
import '../../domain/repositories/goal_settings_repository.dart';
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../infrastructure/storage/settings_crypto.dart';
import '../database/daos/settings_dao.dart';
import '../sync/sync_log_writer.dart';

/// 学习目标设置仓储实现。
///
/// 存储策略：
/// - key=goal_daily / goal_streak / goal_weekly_rate
/// - value=加密后的 JSON（数字或 null）
///
/// 同步策略：
/// - 写入 settings_bundle update 事件（主机为准，接收端按本机密钥重加密）
class GoalSettingsRepositoryImpl implements GoalSettingsRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] SettingsDao
  /// - [secureStorageService] 安全存储服务（用于管理加密密钥）
  /// - [syncLogWriter] 可选，同步日志写入器（F12）
  GoalSettingsRepositoryImpl({
    required this.dao,
    required SecureStorageService secureStorageService,
    SyncLogWriter? syncLogWriter,
  }) : _crypto = SettingsCrypto(secureStorageService: secureStorageService),
       _sync = syncLogWriter;

  final SettingsDao dao;
  final SettingsCrypto _crypto;
  final SyncLogWriter? _sync;

  static const String keyGoalDaily = 'goal_daily';
  static const String keyGoalStreak = 'goal_streak';
  static const String keyGoalWeeklyRate = 'goal_weekly_rate';

  @override
  Future<GoalSettingsEntity> getGoalSettings() async {
    final defaults = GoalSettingsEntity.defaults();
    // 关键逻辑：允许用户“关闭某类目标”（写入 null）。
    //
    // 约定：
    // - key 不存在：视为“从未配置过”，使用默认值（符合规格默认值）
    // - key 存在但值为 null：视为“用户关闭该目标”，返回 null
    final daily = await _readIntSetting(keyGoalDaily);
    final streak = await _readIntSetting(keyGoalStreak);
    final weekly = await _readIntSetting(keyGoalWeeklyRate);
    return GoalSettingsEntity(
      dailyTarget: daily.exists ? daily.value : defaults.dailyTarget,
      streakTarget: streak.exists ? streak.value : defaults.streakTarget,
      weeklyRateTarget: weekly.exists
          ? weekly.value
          : defaults.weeklyRateTarget,
    );
  }

  @override
  Future<void> saveGoalSettings(GoalSettingsEntity settings) async {
    final map = <String, String>{
      keyGoalDaily: await _crypto.encrypt(jsonEncode(settings.dailyTarget)),
      keyGoalStreak: await _crypto.encrypt(jsonEncode(settings.streakTarget)),
      keyGoalWeeklyRate: await _crypto.encrypt(
        jsonEncode(settings.weeklyRateTarget),
      ),
    };
    await dao.upsertValues(map);

    // v3.0（F12）：记录设置变更（settings_bundle）。
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
      data: <String, dynamic>{
        keyGoalDaily: settings.dailyTarget,
        keyGoalStreak: settings.streakTarget,
        keyGoalWeeklyRate: settings.weeklyRateTarget,
      },
      timestampMs: ts,
    );
  }

  /// 读取一个“可能为空”的 int 设置。
  ///
  /// 返回值：
  /// - exists=false：key 不存在
  /// - exists=true,value=null：key 存在但被用户设置为 null（关闭该目标）
  /// - exists=true,value=int：正常数值
  Future<({bool exists, int? value})> _readIntSetting(String key) async {
    final stored = await dao.getValue(key);
    if (stored == null) return (exists: false, value: null);
    try {
      final decrypted = await _crypto.decrypt(stored);
      final decoded = jsonDecode(decrypted);
      if (decoded == null) return (exists: true, value: null);
      if (decoded is int) return (exists: true, value: decoded);
      if (decoded is num) return (exists: true, value: decoded.toInt());
      return (exists: true, value: int.tryParse(decoded.toString()));
    } catch (_) {
      // 读取失败时回退 null，由上层套用默认值。
      return (exists: false, value: null);
    }
  }
}
