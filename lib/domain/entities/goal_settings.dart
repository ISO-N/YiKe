/// 文件用途：领域实体 - 学习目标设置（每日完成数/连续打卡/本周完成率）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

/// 学习目标设置实体。
///
/// 说明：
/// - 为保持可扩展与向后兼容，字段允许为 null（表示未启用该目标）
/// - 数值含义：
///   - [dailyTarget]：每日完成 N 个任务（done）
///   - [streakTarget]：连续打卡 N 天（consecutiveCompletedDays）
///   - [weeklyRateTarget]：本周完成率 >= N（百分比 0~100）
class GoalSettingsEntity {
  /// 构造函数。
  const GoalSettingsEntity({
    required this.dailyTarget,
    required this.streakTarget,
    required this.weeklyRateTarget,
  });

  /// 每日完成目标（N）。
  final int? dailyTarget;

  /// 连续打卡目标（天）。
  final int? streakTarget;

  /// 本周完成率目标（百分比 0~100）。
  final int? weeklyRateTarget;

  /// 默认目标（与 spec-user-experience-improvements.md 一致）。
  factory GoalSettingsEntity.defaults() {
    return const GoalSettingsEntity(
      dailyTarget: 10,
      streakTarget: 7,
      weeklyRateTarget: 80,
    );
  }

  /// 拷贝并修改。
  GoalSettingsEntity copyWith({
    int? dailyTarget,
    int? streakTarget,
    int? weeklyRateTarget,
    bool clearDaily = false,
    bool clearStreak = false,
    bool clearWeeklyRate = false,
  }) {
    return GoalSettingsEntity(
      dailyTarget: clearDaily ? null : (dailyTarget ?? this.dailyTarget),
      streakTarget: clearStreak ? null : (streakTarget ?? this.streakTarget),
      weeklyRateTarget: clearWeeklyRate
          ? null
          : (weeklyRateTarget ?? this.weeklyRateTarget),
    );
  }
}
