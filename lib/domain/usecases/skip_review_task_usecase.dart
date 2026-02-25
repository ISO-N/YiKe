/// 文件用途：用例 - 跳过复习任务（单个/批量）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../repositories/review_task_repository.dart';

/// 跳过复习任务用例。
class SkipReviewTaskUseCase {
  /// 构造函数。
  const SkipReviewTaskUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 跳过单个任务。
  ///
  /// 参数：
  /// - [id] 任务 ID
  /// 返回值：Future（无返回值）。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<void> execute(int id) {
    return _reviewTaskRepository.skipTask(id);
  }

  /// 批量跳过任务。
  ///
  /// 参数：
  /// - [ids] 任务 ID 列表
  /// 返回值：Future（无返回值）。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<void> executeBatch(List<int> ids) {
    return _reviewTaskRepository.skipTasks(ids);
  }
}

