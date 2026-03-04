/// 文件用途：领域实体 - 统计增强数据（趋势图/热力图/对比分析），用于用户体验改进规格 v1.4.0。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'task_day_stats.dart';

/// 趋势图数据点（完成率口径）。
///
/// 说明：
/// - completed：done 数量
/// - total：done + pending 数量（skipped 不计入 total）
class StatisticsTrendPointEntity {
  /// 构造函数。
  const StatisticsTrendPointEntity({
    required this.date,
    required this.completed,
    required this.total,
  });

  /// 点归属的日期（自然日 00:00 或月份起始日 00:00）。
  final DateTime date;

  /// 完成数（done）。
  final int completed;

  /// 总数（done + pending，skipped 不计入）。
  final int total;

  /// 完成率百分比（0~100）。
  double get completionRatePercent => total <= 0 ? 0 : (completed / total) * 100;
}

/// 本周与上周对比分析结果。
class WeekCompareEntity {
  /// 构造函数。
  const WeekCompareEntity({
    required this.thisCompleted,
    required this.thisTotal,
    required this.lastCompleted,
    required this.lastTotal,
    required this.daysInPeriod,
    required this.isInProgress,
  });

  /// 本周期完成数（done）。
  final int thisCompleted;

  /// 本周期总数（done + pending）。
  final int thisTotal;

  /// 对比周期完成数（done）。
  final int lastCompleted;

  /// 对比周期总数（done + pending）。
  final int lastTotal;

  /// 本周期统计天数（1~7）。
  final int daysInPeriod;

  /// 本周是否未结束（用于展示“进行中 x/7 天”与“上周同期”）。
  final bool isInProgress;

  /// 本周期完成率（0~100）。
  double get thisRatePercent =>
      thisTotal <= 0 ? 0 : (thisCompleted / thisTotal) * 100;

  /// 对比周期完成率（0~100）。
  double get lastRatePercent =>
      lastTotal <= 0 ? 0 : (lastCompleted / lastTotal) * 100;

  /// 完成数差值（本周-上周）。
  int get diffCompleted => thisCompleted - lastCompleted;

  /// 完成率差值（百分点，本周-上周）。
  double get diffRatePercent => thisRatePercent - lastRatePercent;

  /// 是否可展示对比（上周同期 total>0 才有意义）。
  bool get hasCompareData => lastTotal > 0;
}

/// 统计增强数据聚合。
class StatisticsInsightsEntity {
  /// 构造函数。
  const StatisticsInsightsEntity({
    required this.weekPoints,
    required this.monthPoints,
    required this.yearPoints,
    required this.todayStats,
    required this.weekCompare,
  });

  /// 本周趋势（7 个点）。
  final List<StatisticsTrendPointEntity> weekPoints;

  /// 本月趋势（按天，N 个点）。
  final List<StatisticsTrendPointEntity> monthPoints;

  /// 本年趋势（按月聚合，12 个点）。
  final List<StatisticsTrendPointEntity> yearPoints;

  /// 今日任务统计（用于“每日完成数”目标）。
  final TaskDayStats todayStats;

  /// 周对比分析（本周 vs 上周同期）。
  final WeekCompareEntity weekCompare;
}
