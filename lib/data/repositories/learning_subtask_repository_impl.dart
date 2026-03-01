/// 文件用途：学习子任务仓储实现（LearningSubtaskRepositoryImpl）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/learning_subtask.dart';
import '../../domain/repositories/learning_subtask_repository.dart';
import '../database/daos/learning_subtask_dao.dart';
import '../database/database.dart';
import '../sync/sync_log_writer.dart';

/// 学习子任务仓储实现。
class LearningSubtaskRepositoryImpl implements LearningSubtaskRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 学习子任务 DAO
  /// - [syncLogWriter] 同步日志写入器（可选；为空表示未启用同步）
  LearningSubtaskRepositoryImpl({
    required this.dao,
    SyncLogWriter? syncLogWriter,
  }) : _sync = syncLogWriter;

  final LearningSubtaskDao dao;
  final SyncLogWriter? _sync;

  static const Uuid _uuid = Uuid();

  @override
  Future<List<LearningSubtaskEntity>> getByLearningItemId(int learningItemId) async {
    final rows = await dao.getByLearningItemId(learningItemId);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<LearningSubtaskEntity>> getByLearningItemIds(
    List<int> learningItemIds,
  ) async {
    final rows = await dao.getByLearningItemIds(learningItemIds);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<LearningSubtaskEntity> create(LearningSubtaskEntity subtask) async {
    final now = DateTime.now();
    final ensuredUuid =
        subtask.uuid.trim().isEmpty ? _uuid.v4() : subtask.uuid.trim();

    final id = await dao.insertSubtask(
      LearningSubtasksCompanion.insert(
        uuid: Value(ensuredUuid),
        learningItemId: subtask.learningItemId,
        content: subtask.content,
        sortOrder: Value(subtask.sortOrder),
        createdAt: subtask.createdAt,
        updatedAt: Value(now),
        isMockData: Value(subtask.isMockData),
      ),
    );

    final saved = subtask.copyWith(id: id, uuid: ensuredUuid, updatedAt: now);

    final sync = _sync;
    if (sync == null || saved.isMockData) return saved;

    final ts = now.millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'learning_subtask',
      localEntityId: id,
      appliedAtMs: ts,
    );
    final learningOrigin = await sync.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: saved.learningItemId,
      appliedAtMs: ts,
    );

    await sync.logEvent(
      origin: origin,
      entityType: 'learning_subtask',
      operation: 'create',
      data: {
        'uuid': saved.uuid,
        'learning_origin_device_id': learningOrigin.deviceId,
        'learning_origin_entity_id': learningOrigin.entityId,
        'content': saved.content,
        'sort_order': saved.sortOrder,
        'created_at': saved.createdAt.toIso8601String(),
        'updated_at': (saved.updatedAt ?? saved.createdAt).toIso8601String(),
        'is_mock_data': saved.isMockData,
      },
      timestampMs: ts,
    );

    return saved;
  }

  @override
  Future<LearningSubtaskEntity> update(LearningSubtaskEntity subtask) async {
    if (subtask.id == null) {
      throw ArgumentError('更新子任务时 id 不能为空');
    }

    final now = DateTime.now();
    final ok = await dao.updateSubtask(
      LearningSubtask(
        id: subtask.id!,
        uuid: subtask.uuid,
        learningItemId: subtask.learningItemId,
        content: subtask.content,
        sortOrder: subtask.sortOrder,
        createdAt: subtask.createdAt,
        updatedAt: now,
        isMockData: subtask.isMockData,
      ),
    );
    if (!ok) {
      throw StateError('子任务更新失败（id=${subtask.id}）');
    }

    final saved = subtask.copyWith(updatedAt: now);

    final sync = _sync;
    if (sync == null || saved.isMockData) return saved;

    final ts = now.millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'learning_subtask',
      localEntityId: subtask.id!,
      appliedAtMs: ts,
    );
    final learningOrigin = await sync.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: saved.learningItemId,
      appliedAtMs: ts,
    );

    await sync.logEvent(
      origin: origin,
      entityType: 'learning_subtask',
      operation: 'update',
      data: {
        'uuid': saved.uuid,
        'learning_origin_device_id': learningOrigin.deviceId,
        'learning_origin_entity_id': learningOrigin.entityId,
        'content': saved.content,
        'sort_order': saved.sortOrder,
        'created_at': saved.createdAt.toIso8601String(),
        'updated_at': (saved.updatedAt ?? saved.createdAt).toIso8601String(),
        'is_mock_data': saved.isMockData,
      },
      timestampMs: ts,
    );

    return saved;
  }

  @override
  Future<void> delete(int id) async {
    // 读取一次用于判定是否为 Mock 数据与补齐同步事件字段。
    final row = await (dao.db.select(dao.db.learningSubtasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    final isMockData = row.isMockData;
    if (!isMockData) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await _sync?.logDelete(
        entityType: 'learning_subtask',
        localEntityId: id,
        timestampMs: ts,
      );
    }

    await dao.deleteSubtask(id);
  }

  @override
  Future<void> reorder(int learningItemId, List<int> subtaskIds) async {
    await dao.reorderSubtasks(learningItemId, subtaskIds);

    final sync = _sync;
    if (sync == null) return;

    // 读取最新排序并逐条写入 update 日志（简化协议：不引入批量事件类型）。
    final rows = await dao.getByLearningItemId(learningItemId);
    if (rows.isEmpty) return;
    if (rows.first.isMockData) return;

    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final learningOrigin = await sync.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: learningItemId,
      appliedAtMs: ts,
    );

    for (final row in rows) {
      final origin = await sync.resolveOriginKey(
        entityType: 'learning_subtask',
        localEntityId: row.id,
        appliedAtMs: ts,
      );
      await sync.logEvent(
        origin: origin,
        entityType: 'learning_subtask',
        operation: 'update',
        data: {
          'uuid': row.uuid,
          'learning_origin_device_id': learningOrigin.deviceId,
          'learning_origin_entity_id': learningOrigin.entityId,
          'content': row.content,
          'sort_order': row.sortOrder,
          'created_at': row.createdAt.toIso8601String(),
          'updated_at': (row.updatedAt ?? row.createdAt).toIso8601String(),
          'is_mock_data': row.isMockData,
        },
        timestampMs: ts,
      );
    }
  }

  LearningSubtaskEntity _toEntity(LearningSubtask row) {
    return LearningSubtaskEntity(
      uuid: row.uuid,
      id: row.id,
      learningItemId: row.learningItemId,
      content: row.content,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isMockData: row.isMockData,
    );
  }
}
