/// 文件用途：用例 - 完成复习任务（单个/批量）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../repositories/review_task_repository.dart';

/// 完成复习任务用例。
class CompleteReviewTaskUseCase {
  /// 构造函数。
  const CompleteReviewTaskUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 完成单个任务。
  ///
  /// 参数：
  /// - [id] 任务 ID
  /// 返回值：Future（无返回值）。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<void> execute(int id) {
    return _reviewTaskRepository.completeTask(id);
  }

  /// 批量完成任务。
  ///
  /// 参数：
  /// - [ids] 任务 ID 列表
  /// 返回值：Future（无返回值）。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<void> executeBatch(List<int> ids) {
    return _reviewTaskRepository.completeTasks(ids);
  }
}

