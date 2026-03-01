/// 文件用途：用例 - 更新学习子任务（内容/排序）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../entities/learning_subtask.dart';
import '../repositories/learning_item_repository.dart';
import '../repositories/learning_subtask_repository.dart';

/// 更新子任务用例。
class UpdateSubtaskUseCase {
  /// 构造函数。
  const UpdateSubtaskUseCase({
    required LearningItemRepository learningItemRepository,
    required LearningSubtaskRepository learningSubtaskRepository,
  }) : _learningItemRepository = learningItemRepository,
       _learningSubtaskRepository = learningSubtaskRepository;

  final LearningItemRepository _learningItemRepository;
  final LearningSubtaskRepository _learningSubtaskRepository;

  /// 更新子任务。
  ///
  /// 规则：
  /// - 学习内容不存在/已停用则拒绝更新
  /// - content 会 trim；空内容抛异常
  Future<LearningSubtaskEntity> execute(LearningSubtaskEntity subtask) async {
    if (subtask.id == null) {
      throw ArgumentError('更新子任务时 id 不能为空');
    }
    final item = await _learningItemRepository.getById(subtask.learningItemId);
    if (item == null) {
      throw StateError('学习内容不存在（learningItemId=${subtask.learningItemId}）');
    }
    if (item.isDeleted) {
      throw StateError('学习内容已停用，无法编辑子任务');
    }

    final normalized = subtask.content.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('子任务内容不能为空');
    }

    final now = DateTime.now();
    return _learningSubtaskRepository.update(
      subtask.copyWith(content: normalized, updatedAt: now),
    );
  }
}

