/// 文件用途：仓储接口 - 学习主题（LearningTopicRepository），用于内容关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import '../entities/learning_topic.dart';
import '../entities/learning_topic_overview.dart';

/// 学习主题仓储接口。
abstract class LearningTopicRepository {
  /// 创建主题。
  Future<LearningTopicEntity> create(LearningTopicEntity topic);

  /// 更新主题。
  Future<LearningTopicEntity> update(LearningTopicEntity topic);

  /// 删除主题（仅解除关联，不删除学习内容）。
  Future<void> delete(int id);

  /// 根据 ID 获取主题。
  Future<LearningTopicEntity?> getById(int id);

  /// 获取全部主题。
  Future<List<LearningTopicEntity>> getAll();

  /// 获取主题概览（含条目数与进度）。
  Future<List<LearningTopicOverviewEntity>> getOverviews();

  /// 将学习内容加入主题。
  Future<void> addItemToTopic(int topicId, int learningItemId);

  /// 将学习内容从主题移除。
  Future<void> removeItemFromTopic(int topicId, int learningItemId);

  /// 获取主题关联的学习内容 ID 列表。
  Future<List<int>> getItemIdsByTopicId(int topicId);

  /// 检查主题名称是否已存在。
  Future<bool> existsName(String name, {int? exceptId});
}
