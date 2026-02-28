/// 文件用途：用例 - 停用学习内容（软删除 LearningItem）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../repositories/learning_item_repository.dart';

/// 停用学习内容用例。
class DeactivateLearningItemUseCase {
  /// 构造函数。
  const DeactivateLearningItemUseCase({
    required LearningItemRepository learningItemRepository,
  }) : _learningItemRepository = learningItemRepository;

  final LearningItemRepository _learningItemRepository;

  /// 执行停用（软删除）。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// 返回值：Future（无返回值）。
  /// 异常：学习内容不存在/更新失败时可能抛出异常。
  Future<void> execute(int learningItemId) {
    return _learningItemRepository.deactivate(learningItemId);
  }
}

