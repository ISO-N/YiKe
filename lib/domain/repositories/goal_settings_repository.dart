/// 文件用途：仓储接口 - 学习目标设置（GoalSettingsRepository）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import '../entities/goal_settings.dart';

/// 学习目标设置仓储接口。
///
/// 说明：
/// - 持久化存储在 settings 表（key-value，加密）
/// - 参与 F12 同步（settings_bundle）
abstract class GoalSettingsRepository {
  /// 获取学习目标设置（若未写入则返回默认目标）。
  Future<GoalSettingsEntity> getGoalSettings();

  /// 保存学习目标设置（整体覆盖）。
  Future<void> saveGoalSettings(GoalSettingsEntity settings);
}

