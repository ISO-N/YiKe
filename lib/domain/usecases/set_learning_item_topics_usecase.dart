/// 文件用途：用例 - 设置学习内容关联主题（TopicItemRelations），支持多选并做差量更新。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import '../repositories/learning_item_repository.dart';
import '../repositories/learning_topic_repository.dart';

/// 设置学习内容主题关联用例。
///
/// 说明：
/// - 数据层为多对多（topic_item_relations），因此这里支持多选主题
/// - 为避免误删/重复写入，只做差量 add/remove
class SetLearningItemTopicsUseCase {
  /// 构造函数。
  const SetLearningItemTopicsUseCase({
    required LearningTopicRepository learningTopicRepository,
    required LearningItemRepository learningItemRepository,
  }) : _learningTopicRepository = learningTopicRepository,
       _learningItemRepository = learningItemRepository;

  final LearningTopicRepository _learningTopicRepository;
  final LearningItemRepository _learningItemRepository;

  /// 执行设置。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// - [topicIds] 目标主题 ID 集合（可为空，表示清空关联）
  ///
  /// 返回值：无。
  /// 异常：
  /// - 学习内容不存在时抛出 [StateError]
  /// - 学习内容已停用时抛出 [StateError]
  Future<void> execute({
    required int learningItemId,
    required Set<int> topicIds,
  }) async {
    final item = await _learningItemRepository.getById(learningItemId);
    if (item == null) {
      throw StateError('学习内容不存在（id=$learningItemId）');
    }
    if (item.isDeleted) {
      throw StateError('学习内容已停用，无法编辑主题关联（id=$learningItemId）');
    }

    // 关键逻辑：仓储接口当前没有“按学习内容查询关联主题”的专用方法，
    // 因此这里通过 getAll() 携带的 itemIds 反查当前关联集合。
    final allTopics = await _learningTopicRepository.getAll();
    final current = <int>{};
    for (final t in allTopics) {
      final id = t.id;
      if (id == null) continue;
      if (t.itemIds.contains(learningItemId)) current.add(id);
    }

    final desired = topicIds;
    final toAdd = desired.difference(current);
    final toRemove = current.difference(desired);

    // 先移除再添加：避免 uniqueKeys/约束与 UI 先选后撤销的边界条件冲突。
    for (final id in toRemove) {
      await _learningTopicRepository.removeItemFromTopic(id, learningItemId);
    }
    for (final id in toAdd) {
      await _learningTopicRepository.addItemToTopic(id, learningItemId);
    }
  }
}

