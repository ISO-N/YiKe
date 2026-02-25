/// 文件用途：用例 - 获取首页所需数据（今日任务、逾期任务、进度统计）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/review_task.dart';
import '../repositories/review_task_repository.dart';

/// 首页任务聚合结果。
class HomeTasksResult {
  const HomeTasksResult({
    required this.todayPending,
    required this.overduePending,
    required this.completedCount,
    required this.totalCount,
  });

  final List<ReviewTaskViewEntity> todayPending;
  final List<ReviewTaskViewEntity> overduePending;
  final int completedCount;
  final int totalCount;
}

/// 获取首页数据用例。
class GetHomeTasksUseCase {
  /// 构造函数。
  const GetHomeTasksUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行用例。
  ///
  /// 返回值：首页数据结果。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<HomeTasksResult> execute({DateTime? date}) async {
    final target = date ?? DateTime.now();
    final todayPending = await _reviewTaskRepository.getTodayPendingTasks();
    final overduePending = await _reviewTaskRepository.getOverduePendingTasks();
    final (completed, total) = await _reviewTaskRepository.getTaskStats(target);
    return HomeTasksResult(
      todayPending: todayPending,
      overduePending: overduePending,
      completedCount: completed,
      totalCount: total,
    );
  }
}

