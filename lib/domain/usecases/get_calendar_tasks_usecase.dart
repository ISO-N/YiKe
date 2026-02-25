/// 文件用途：用例 - 获取日历视图所需数据（月份任务统计、日期任务列表）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/review_task.dart';
import '../entities/task_day_stats.dart';
import '../repositories/review_task_repository.dart';

/// 日历月份聚合结果。
class CalendarMonthResult {
  /// 构造函数。
  const CalendarMonthResult({required this.dayStats});

  /// 单日统计（key 为当天 00:00:00）。
  final Map<DateTime, TaskDayStats> dayStats;
}

/// 获取日历数据用例（F6）。
///
/// 说明：
/// - 月历圆点：按月拉取单日统计
/// - 点击日期：拉取当日任务列表（含学习内容信息）
class GetCalendarTasksUseCase {
  /// 构造函数。
  const GetCalendarTasksUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 获取指定月份的单日任务统计。
  ///
  /// 参数：
  /// - [year] 年份
  /// - [month] 月份（1-12）
  /// 返回值：[CalendarMonthResult]。
  Future<CalendarMonthResult> execute({
    required int year,
    required int month,
  }) async {
    final stats = await _reviewTaskRepository.getMonthlyTaskStats(year, month);
    return CalendarMonthResult(dayStats: stats);
  }

  /// 获取指定日期的任务列表（含学习内容信息）。
  Future<List<ReviewTaskViewEntity>> getTasksByDate(DateTime date) {
    return _reviewTaskRepository.getTasksByDate(date);
  }

  /// 获取指定范围内的任务列表（含学习内容信息）。
  Future<List<ReviewTaskViewEntity>> getTasksInRange(DateTime start, DateTime end) {
    return _reviewTaskRepository.getTasksInRange(start, end);
  }
}

