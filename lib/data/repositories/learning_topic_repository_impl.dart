/// 文件用途：学习主题仓储实现（LearningTopicRepositoryImpl），用于内容关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import '../../domain/entities/learning_topic.dart';
import '../../domain/entities/learning_topic_overview.dart';
import '../../domain/repositories/learning_topic_repository.dart';
import '../database/daos/learning_topic_dao.dart';
import '../database/database.dart';

/// 学习主题仓储实现。
class LearningTopicRepositoryImpl implements LearningTopicRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 主题 DAO。
  /// 异常：无。
  LearningTopicRepositoryImpl(this.dao);

  final LearningTopicDao dao;

  @override
  Future<LearningTopicEntity> create(LearningTopicEntity topic) async {
    final now = DateTime.now();
    final id = await dao.insertTopic(
      LearningTopicsCompanion.insert(
        name: topic.name.trim(),
        description: topic.description == null
            ? const Value.absent()
            : Value(topic.description),
        createdAt: Value(topic.createdAt),
        updatedAt: Value(now),
      ),
    );
    return topic.copyWith(id: id, updatedAt: now);
  }

  @override
  Future<void> delete(int id) async {
    await dao.deleteTopic(id);
  }

  @override
  Future<List<LearningTopicEntity>> getAll() async {
    final rows = await dao.getAllTopics();
    final topics = <LearningTopicEntity>[];
    for (final row in rows) {
      final itemIds = await dao.getItemIdsByTopicId(row.id);
      topics.add(_toEntity(row).copyWith(itemIds: itemIds));
    }
    return topics;
  }

  @override
  Future<LearningTopicEntity?> getById(int id) async {
    final row = await dao.getById(id);
    if (row == null) return null;
    final itemIds = await dao.getItemIdsByTopicId(row.id);
    return _toEntity(row).copyWith(itemIds: itemIds);
  }

  @override
  Future<LearningTopicEntity> update(LearningTopicEntity topic) async {
    if (topic.id == null) {
      throw ArgumentError('更新主题时 id 不能为空');
    }
    final now = DateTime.now();
    final ok = await dao.updateTopic(
      LearningTopic(
        id: topic.id!,
        name: topic.name.trim(),
        description: topic.description,
        createdAt: topic.createdAt,
        updatedAt: now,
      ),
    );
    if (!ok) {
      throw StateError('主题更新失败（id=${topic.id}）');
    }
    return topic.copyWith(updatedAt: now);
  }

  @override
  Future<void> addItemToTopic(int topicId, int learningItemId) {
    return dao.addItemToTopic(topicId, learningItemId);
  }

  @override
  Future<List<int>> getItemIdsByTopicId(int topicId) {
    return dao.getItemIdsByTopicId(topicId);
  }

  @override
  Future<void> removeItemFromTopic(int topicId, int learningItemId) async {
    await dao.removeItemFromTopic(topicId, learningItemId);
  }

  @override
  Future<List<LearningTopicOverviewEntity>> getOverviews() async {
    final rows = await dao.getTopicOverviews();
    return rows
        .map(
          (row) => LearningTopicOverviewEntity(
            topic: _toEntity(row.topic),
            itemCount: row.itemCount,
            completedCount: row.completedCount,
            totalCount: row.totalCount,
          ),
        )
        .toList();
  }

  @override
  Future<bool> existsName(String name, {int? exceptId}) {
    return dao.existsName(name, exceptId: exceptId);
  }

  LearningTopicEntity _toEntity(LearningTopic row) {
    return LearningTopicEntity(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
