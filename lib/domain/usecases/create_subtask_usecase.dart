/// 文件用途：用例 - 创建学习子任务（LearningSubtask）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:uuid/uuid.dart';

import '../entities/learning_subtask.dart';
import '../repositories/learning_item_repository.dart';
import '../repositories/learning_subtask_repository.dart';

/// 创建子任务用例。
class CreateSubtaskUseCase {
  /// 构造函数。
  const CreateSubtaskUseCase({
    required LearningItemRepository learningItemRepository,
    required LearningSubtaskRepository learningSubtaskRepository,
  }) : _learningItemRepository = learningItemRepository,
       _learningSubtaskRepository = learningSubtaskRepository;

  final LearningItemRepository _learningItemRepository;
  final LearningSubtaskRepository _learningSubtaskRepository;

  static const Uuid _uuid = Uuid();

  /// 创建子任务（默认追加到末尾）。
  ///
  /// 规则：
  /// - 学习内容不存在/已停用则拒绝创建
  /// - content 会 trim；空内容抛异常
  Future<LearningSubtaskEntity> execute({
    required int learningItemId,
    required String content,
  }) async {
    final item = await _learningItemRepository.getById(learningItemId);
    if (item == null) {
      throw StateError('学习内容不存在（learningItemId=$learningItemId）');
    }
    if (item.isDeleted) {
      throw StateError('学习内容已停用，无法添加子任务');
    }

    final normalized = content.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('子任务内容不能为空');
    }

    final existing = await _learningSubtaskRepository.getByLearningItemId(
      learningItemId,
    );
    final nextSort =
        existing.isEmpty
            ? 0
            : existing
                  .map((e) => e.sortOrder)
                  .fold<int>(0, (a, b) => a > b ? a : b) +
              1;

    final now = DateTime.now();
    final entity = LearningSubtaskEntity(
      uuid: _uuid.v4(),
      learningItemId: learningItemId,
      content: normalized,
      sortOrder: nextSort,
      createdAt: now,
      updatedAt: now,
      isMockData: item.isMockData,
    );
    return _learningSubtaskRepository.create(entity);
  }
}

