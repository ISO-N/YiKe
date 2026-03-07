/// 文件用途：用例 - 获取统计增强数据（趋势图/热力图/对比分析），用于用户体验改进规格 v1.4.0。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import '../../core/utils/date_utils.dart';
import '../entities/statistics_insights.dart';
import '../entities/task_day_stats.dart';
import '../repositories/review_task_repository.dart';

/// 获取统计增强数据用例。
///
/// 说明：
/// - 该用例聚合“趋势图/热力图/对比分析/今日统计”等统计增强所需数据。
/// - 口径严格按 spec-user-experience-improvements.md：
///   - 归因日期：scheduledDate（计划复习日）
///   - 完成率：done / (done + pending) * 100%（skipped 不计入 total）
///   - 周起始日：周一
class GetStatisticsInsightsUseCase {
  /// 构造函数。
  ///
  /// 参数：
  /// - [reviewTaskRepository] 复习任务仓储
  const GetStatisticsInsightsUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行用例。
  ///
  /// 参数：
  /// - [today] 用于测试/注入的“今天”（默认取当前时间）
  /// 返回值：[StatisticsInsightsEntity]。
  /// 异常：底层仓储查询失败时可能抛出异常。
  Future<StatisticsInsightsEntity> execute({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final todayStart = YikeDateUtils.atStartOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // 本周：按周一为一周起点（ISO 习惯）。
    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - DateTime.monday),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));

    // 本月：从 1 号 00:00 到下月 1 号 00:00。
    final monthStart = DateTime(todayStart.year, todayStart.month, 1);
    final monthEnd = DateTime(todayStart.year, todayStart.month + 1, 1);

    // 今日：用于“每日完成数”目标。
    final todayStatsMap = await _reviewTaskRepository.getTaskDayStatsInRange(
      todayStart,
      tomorrowStart,
    );
    final todayStats = todayStatsMap[todayStart] ?? _emptyDayStats();

    // 周/月：趋势图按天补齐缺失日期（无任务补 0）。
    final weekDayStats = await _reviewTaskRepository.getTaskDayStatsInRange(
      weekStart,
      weekEnd,
    );
    final monthDayStats = await _reviewTaskRepository.getTaskDayStatsInRange(
      monthStart,
      monthEnd,
    );

    final weekPoints = _buildDailyPoints(
      start: weekStart,
      end: weekEnd,
      statsByDay: weekDayStats,
    );
    final monthPoints = _buildDailyPoints(
      start: monthStart,
      end: monthEnd,
      statsByDay: monthDayStats,
    );
    final yearPoints = await _buildMonthlyPointsByQuery(year: todayStart.year);

    final weekCompare = await _buildWeekCompare(
      todayStart: todayStart,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );

    return StatisticsInsightsEntity(
      weekPoints: weekPoints,
      monthPoints: monthPoints,
      yearPoints: yearPoints,
      todayStats: todayStats,
      weekCompare: weekCompare,
    );
  }

  /// 生成指定日期范围（按天）的趋势点。
  ///
  /// 说明：范围为 [start, end)，会补齐缺失日期（无任务补 0）。
  List<StatisticsTrendPointEntity> _buildDailyPoints({
    required DateTime start,
    required DateTime end,
    required Map<DateTime, TaskDayStats> statsByDay,
  }) {
    final days = end.difference(start).inDays;
    return List<StatisticsTrendPointEntity>.generate(days, (i) {
      final day = start.add(Duration(days: i));
      final stats = statsByDay[day] ?? _emptyDayStats();
      final completed = stats.doneCount;
      final total = stats.doneCount + stats.pendingCount;
      return StatisticsTrendPointEntity(
        date: day,
        completed: completed,
        total: total,
      );
    });
  }

  /// 生成指定年份（按月聚合）的趋势点（12 个点）。
  ///
  /// 说明：
  /// - 使用聚合查询按月计算，避免一次性拉取全年日粒度数据影响首屏渲染
  /// - 统计口径保持一致：total=done+pending，skipped 不计入 total
  Future<List<StatisticsTrendPointEntity>> _buildMonthlyPointsByQuery({
    required int year,
  }) async {
    final points = <StatisticsTrendPointEntity>[];
    for (var month = 1; month <= 12; month++) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      final (completed, total) = await _reviewTaskRepository
          .getTaskStatsInRange(start, end);
      points.add(
        StatisticsTrendPointEntity(
          date: start,
          completed: completed,
          total: total,
        ),
      );
    }
    return points;
  }

  Future<WeekCompareEntity> _buildWeekCompare({
    required DateTime todayStart,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    // 本周未结束时，对比“上周同期”（例如周三则比较上周一~周三）。
    // 关键逻辑：daysInPeriod 取 1~7，且 end 为 start + days（区间为 [start, end)）。
    final daysInPeriod = (todayStart.difference(weekStart).inDays + 1).clamp(
      1,
      7,
    );
    final thisEnd = weekStart.add(Duration(days: daysInPeriod));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastEnd = lastWeekStart.add(Duration(days: daysInPeriod));

    final (thisCompleted, thisTotal) = await _reviewTaskRepository
        .getTaskStatsInRange(weekStart, thisEnd);
    final (lastCompleted, lastTotal) = await _reviewTaskRepository
        .getTaskStatsInRange(lastWeekStart, lastEnd);

    final isInProgress = todayStart.isBefore(weekEnd);
    return WeekCompareEntity(
      thisCompleted: thisCompleted,
      thisTotal: thisTotal,
      lastCompleted: lastCompleted,
      lastTotal: lastTotal,
      daysInPeriod: daysInPeriod,
      isInProgress: isInProgress,
    );
  }

  TaskDayStats _emptyDayStats() {
    return const TaskDayStats(pendingCount: 0, doneCount: 0, skippedCount: 0);
  }
}
