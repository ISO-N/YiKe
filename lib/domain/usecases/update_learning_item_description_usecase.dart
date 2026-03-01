/// 文件用途：用例 - 更新学习内容描述（LearningItem.description）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../repositories/learning_item_repository.dart';

/// 更新学习内容描述用例。
class UpdateLearningItemDescriptionUseCase {
  /// 构造函数。
  const UpdateLearningItemDescriptionUseCase({
    required LearningItemRepository learningItemRepository,
  }) : _learningItemRepository = learningItemRepository;

  final LearningItemRepository _learningItemRepository;

  /// 执行更新。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// - [description] 描述（可空；空字符串会被归一为 null）
  Future<void> execute({
    required int learningItemId,
    required String? description,
  }) {
    return _learningItemRepository.updateDescription(
      id: learningItemId,
      description: description,
    );
  }
}

