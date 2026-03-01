/// 文件用途：用例 - 删除学习子任务。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../repositories/learning_subtask_repository.dart';

/// 删除子任务用例。
class DeleteSubtaskUseCase {
  /// 构造函数。
  const DeleteSubtaskUseCase({
    required LearningSubtaskRepository learningSubtaskRepository,
  }) : _learningSubtaskRepository = learningSubtaskRepository;

  final LearningSubtaskRepository _learningSubtaskRepository;

  /// 删除子任务。
  Future<void> execute(int id) => _learningSubtaskRepository.delete(id);
}

