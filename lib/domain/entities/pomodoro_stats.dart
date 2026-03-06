/// 文件用途：领域实体 - 番茄钟统计摘要（PomodoroStatsEntity）。
/// 作者：Codex
/// 创建日期：2026-03-06
library;

/// 番茄钟统计摘要。
class PomodoroStatsEntity {
  /// 构造函数。
  const PomodoroStatsEntity({
    required this.todayCompletedCount,
    required this.weekCompletedCount,
    required this.totalFocusMinutes,
  });

  /// 今日完成数。
  final int todayCompletedCount;

  /// 本周完成数。
  final int weekCompletedCount;

  /// 累计专注分钟数。
  final int totalFocusMinutes;

  /// 默认空统计。
  static const PomodoroStatsEntity empty = PomodoroStatsEntity(
    todayCompletedCount: 0,
    weekCompletedCount: 0,
    totalFocusMinutes: 0,
  );
}
