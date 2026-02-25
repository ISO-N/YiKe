/// 文件用途：仓储接口 - 复习任务（ReviewTaskRepository）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/review_task.dart';
import '../entities/task_day_stats.dart';

/// 复习任务仓储接口。
abstract class ReviewTaskRepository {
  /// 创建单个复习任务。
  Future<ReviewTaskEntity> create(ReviewTaskEntity task);

  /// 批量创建复习任务。
  Future<List<ReviewTaskEntity>> createBatch(List<ReviewTaskEntity> tasks);

  /// 获取今日待复习任务（pending）。
  Future<List<ReviewTaskViewEntity>> getTodayPendingTasks();

  /// 获取逾期待复习任务（pending，scheduledDate < 今日）。
  Future<List<ReviewTaskViewEntity>> getOverduePendingTasks();

  /// 获取指定日期的全部任务（包含完成/跳过），用于小组件与通知内容生成。
  Future<List<ReviewTaskViewEntity>> getTasksByDate(DateTime date);

  /// 标记任务完成。
  Future<void> completeTask(int id);

  /// 标记任务跳过。
  Future<void> skipTask(int id);

  /// 批量标记完成。
  Future<void> completeTasks(List<int> ids);

  /// 批量标记跳过。
  Future<void> skipTasks(List<int> ids);

  /// 获取指定日期统计（completed/total）。
  Future<(int completed, int total)> getTaskStats(DateTime date);

  /// F6：获取指定月份每天的任务统计（用于日历圆点标记）。
  ///
  /// 返回值：以“当天 00:00:00”为 key 的统计 Map。
  Future<Map<DateTime, TaskDayStats>> getMonthlyTaskStats(int year, int month);

  /// F6：获取指定日期范围的任务列表（含学习内容信息）。
  ///
  /// 参数：
  /// - [start] 起始时间（包含）
  /// - [end] 结束时间（不包含）
  Future<List<ReviewTaskViewEntity>> getTasksInRange(DateTime start, DateTime end);

  /// F7：获取连续打卡天数。
  ///
  /// 口径：
  /// - 从今天往前，连续每天至少完成 1 条任务算打卡成功
  /// - 跳过(skipped)不算断签，也不算完成
  /// - 某天没有任务，不中断打卡链
  ///
  /// 参数：
  /// - [today] 用于测试/注入的“今天”（默认取当前时间）
  Future<int> getConsecutiveCompletedDays({DateTime? today});

  /// F7：获取指定日期范围的完成率口径数据。
  ///
  /// 说明：
  /// - 分子：done 数量
  /// - 分母：done + pending 数量（skipped 不参与）
  Future<(int completed, int total)> getTaskStatsInRange(DateTime start, DateTime end);

  /// F8：获取全部复习任务（用于数据导出）。
  Future<List<ReviewTaskEntity>> getAllTasks();
}
