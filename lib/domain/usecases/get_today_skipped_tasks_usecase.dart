/// 文件用途：用例 - 获取今日已跳过任务列表（skippedAt = 今天）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../entities/review_task.dart';
import '../repositories/review_task_repository.dart';

/// 获取今日已跳过任务用例。
class GetTodaySkippedTasksUseCase {
  /// 构造函数。
  const GetTodaySkippedTasksUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行用例。
  ///
  /// 返回值：今日已跳过任务列表（skippedAt 为今天）。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<ReviewTaskViewEntity>> execute() {
    return _reviewTaskRepository.getTodaySkippedTasks();
  }
}

