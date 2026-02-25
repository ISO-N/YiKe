/// 文件用途：仓储接口 - 复习任务（ReviewTaskRepository）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/review_task.dart';

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
}

