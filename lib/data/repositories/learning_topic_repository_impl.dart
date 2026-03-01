/// 文件用途：学习主题仓储实现（LearningTopicRepositoryImpl），用于内容关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/learning_topic.dart';
import '../../domain/entities/learning_topic_overview.dart';
import '../../domain/repositories/learning_topic_repository.dart';
import '../database/daos/learning_topic_dao.dart';
import '../database/database.dart';
import '../sync/sync_log_writer.dart';

/// 学习主题仓储实现。
class LearningTopicRepositoryImpl implements LearningTopicRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 主题 DAO。
  /// 异常：无。
  LearningTopicRepositoryImpl(this.dao, {SyncLogWriter? syncLogWriter})
    : _sync = syncLogWriter;

  final LearningTopicDao dao;
  final SyncLogWriter? _sync;

  static const Uuid _uuid = Uuid();

  @override
  Future<LearningTopicEntity> create(LearningTopicEntity topic) async {
    final now = DateTime.now();
    final ensuredUuid = topic.uuid.trim().isEmpty ? _uuid.v4() : topic.uuid.trim();
    final id = await dao.insertTopic(
      LearningTopicsCompanion.insert(
        uuid: Value(ensuredUuid),
        name: topic.name.trim(),
        description: topic.description == null
            ? const Value.absent()
            : Value(topic.description),
        createdAt: Value(topic.createdAt),
        updatedAt: Value(now),
      ),
    );
    final saved = topic.copyWith(id: id, updatedAt: now, uuid: ensuredUuid);

    final sync = _sync;
    if (sync == null) return saved;

    final ts = now.millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'learning_topic',
      localEntityId: id,
      appliedAtMs: ts,
    );
    await sync.logEvent(
      origin: origin,
      entityType: 'learning_topic',
      operation: 'create',
      data: {
        'name': saved.name,
        'description': saved.description,
        'created_at': saved.createdAt.toIso8601String(),
        'updated_at': (saved.updatedAt ?? saved.createdAt).toIso8601String(),
      },
      timestampMs: ts,
    );

    return saved;
  }

  @override
  Future<void> delete(int id) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    await _sync?.logDelete(
      entityType: 'learning_topic',
      localEntityId: id,
      timestampMs: ts,
    );
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
    final ts = now.millisecondsSinceEpoch;
    final ok = await dao.updateTopic(
      LearningTopic(
        id: topic.id!,
        uuid: topic.uuid,
        name: topic.name.trim(),
        description: topic.description,
        createdAt: topic.createdAt,
        updatedAt: now,
      ),
    );
    if (!ok) {
      throw StateError('主题更新失败（id=${topic.id}）');
    }
    final saved = topic.copyWith(updatedAt: now);

    final sync = _sync;
    if (sync == null) return saved;

    final origin = await sync.resolveOriginKey(
      entityType: 'learning_topic',
      localEntityId: topic.id!,
      appliedAtMs: ts,
    );
    await sync.logEvent(
      origin: origin,
      entityType: 'learning_topic',
      operation: 'update',
      data: {
        'name': saved.name,
        'description': saved.description,
        'created_at': saved.createdAt.toIso8601String(),
        'updated_at': (saved.updatedAt ?? saved.createdAt).toIso8601String(),
      },
      timestampMs: ts,
    );

    return saved;
  }

  @override
  Future<void> addItemToTopic(int topicId, int learningItemId) {
    return _addItemToTopicAndLog(topicId, learningItemId);
  }

  @override
  Future<List<int>> getItemIdsByTopicId(int topicId) {
    return dao.getItemIdsByTopicId(topicId);
  }

  @override
  Future<void> removeItemFromTopic(int topicId, int learningItemId) async {
    final existing = await dao.getRelationByPair(topicId, learningItemId);
    if (existing == null) return;

    await dao.removeItemFromTopic(topicId, learningItemId);

    final sync = _sync;
    if (sync == null) return;

    final ts = DateTime.now().millisecondsSinceEpoch;
    await sync.logDelete(
      entityType: 'topic_item_relation',
      localEntityId: existing.id,
      timestampMs: ts,
    );
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
      uuid: row.uuid,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> _addItemToTopicAndLog(int topicId, int learningItemId) async {
    await dao.addItemToTopic(topicId, learningItemId);
    final relation = await dao.getRelationByPair(topicId, learningItemId);
    if (relation == null) return;

    final sync = _sync;
    if (sync == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'topic_item_relation',
      localEntityId: relation.id,
      appliedAtMs: nowMs,
    );
    final topicOrigin = await sync.resolveOriginKey(
      entityType: 'learning_topic',
      localEntityId: topicId,
      appliedAtMs: nowMs,
    );
    final itemOrigin = await sync.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: learningItemId,
      appliedAtMs: nowMs,
    );

    await sync.logEvent(
      origin: origin,
      entityType: 'topic_item_relation',
      operation: 'create',
      data: {
        'topic_origin_device_id': topicOrigin.deviceId,
        'topic_origin_entity_id': topicOrigin.entityId,
        'item_origin_device_id': itemOrigin.deviceId,
        'item_origin_entity_id': itemOrigin.entityId,
        'created_at': relation.createdAt.toIso8601String(),
      },
      timestampMs: nowMs,
    );
  }
}
