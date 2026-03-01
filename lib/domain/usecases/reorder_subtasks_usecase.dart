/// 文件用途：用例 - 子任务拖拽排序（写入 sortOrder）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../repositories/learning_subtask_repository.dart';

/// 子任务排序用例。
class ReorderSubtasksUseCase {
  /// 构造函数。
  const ReorderSubtasksUseCase({
    required LearningSubtaskRepository learningSubtaskRepository,
  }) : _learningSubtaskRepository = learningSubtaskRepository;

  final LearningSubtaskRepository _learningSubtaskRepository;

  /// 执行排序写入。
  Future<void> execute({
    required int learningItemId,
    required List<int> subtaskIds,
  }) {
    return _learningSubtaskRepository.reorder(learningItemId, subtaskIds);
  }
}

