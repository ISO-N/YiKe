/// 文件用途：任务结构迁移仓储实现（note → description + subtasks）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/task_structure_migration_repository.dart';
import '../database/daos/learning_subtask_dao.dart';
import '../database/database.dart';
import '../sync/sync_log_writer.dart';

/// 任务结构迁移仓储实现。
class TaskStructureMigrationRepositoryImpl
    implements TaskStructureMigrationRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例
  /// - [learningSubtaskDao] 子任务 DAO
  /// - [syncLogWriter] 同步日志写入器（可选）
  TaskStructureMigrationRepositoryImpl({
    required this.db,
    required LearningSubtaskDao learningSubtaskDao,
    SyncLogWriter? syncLogWriter,
  }) : _learningSubtaskDao = learningSubtaskDao,
       _sync = syncLogWriter;

  final AppDatabase db;
  final LearningSubtaskDao _learningSubtaskDao;
  final SyncLogWriter? _sync;

  static const Uuid _uuid = Uuid();

  @override
  Future<List<LegacyNoteMigrationItem>> getPendingLegacyNoteItems({
    int limit = 200,
  }) async {
    final capped = limit.clamp(1, 1000);

    const sql = '''
SELECT id, note, description, is_mock_data
FROM learning_items
WHERE note IS NOT NULL AND TRIM(note) != ''
ORDER BY id ASC
LIMIT ?
''';

    final rows = await db.customSelect(
      sql,
      variables: [Variable<int>(capped)],
      readsFrom: {db.learningItems},
    ).get();

    return rows
        .map(
          (r) => LegacyNoteMigrationItem(
            learningItemId: r.read<int>('id'),
            note: r.read<String>('note'),
            existingDescription: r.read<String?>('description'),
            isMockData: r.read<int>('is_mock_data') == 1,
          ),
        )
        .toList();
  }

  @override
  Future<int> getExistingSubtaskCount(int learningItemId) async {
    final t = db.learningSubtasks;
    final countExp = t.id.count();
    final query = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.learningItemId.equals(learningItemId));
    final row = await query.getSingleOrNull();
    return row?.read(countExp) ?? 0;
  }

  @override
  Future<void> applyMigrationForItem({
    required int learningItemId,
    required bool isMockData,
    required String? migratedDescription,
    required List<String> migratedSubtasks,
  }) async {
    final normalizedDescription =
        migratedDescription?.trim().isEmpty == true
            ? null
            : migratedDescription?.trim();
    final normalizedSubtasks =
        migratedSubtasks.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final now = DateTime.now();
    final insertedSubtaskIds = <int>[];

    await db.transaction(() async {
      final existingSubtaskCount = await getExistingSubtaskCount(learningItemId);

      if (existingSubtaskCount == 0 && normalizedSubtasks.isNotEmpty) {
        for (var i = 0; i < normalizedSubtasks.length; i++) {
          final id = await _learningSubtaskDao.insertSubtask(
            LearningSubtasksCompanion.insert(
              uuid: Value(_uuid.v4()),
              learningItemId: learningItemId,
              content: normalizedSubtasks[i],
              sortOrder: Value(i),
              createdAt: now,
              updatedAt: Value(now),
              isMockData: Value(isMockData),
            ),
          );
          insertedSubtaskIds.add(id);
        }
      }

      // 说明：description 若已存在且非空，则不覆盖（避免用户已开始使用新字段）。
      final existing = await (db.select(db.learningItems)
            ..where((t) => t.id.equals(learningItemId)))
          .getSingleOrNull();
      if (existing == null) return;

      final shouldWriteDescription =
          (existing.description?.trim().isEmpty ?? true) &&
          normalizedDescription != null;

      await (db.update(db.learningItems)
            ..where((t) => t.id.equals(learningItemId)))
          .write(
        LearningItemsCompanion(
          description:
              shouldWriteDescription
                  ? Value(normalizedDescription)
                  : const Value.absent(),
          // 幂等锚点：迁移成功后置空 note。
          note: const Value(null),
          updatedAt: Value(now),
        ),
      );
    });

    // 写入同步日志（仅真实数据）。
    final sync = _sync;
    if (sync == null || isMockData) return;

    final ts = now.millisecondsSinceEpoch;

    // 1) learning_item：写入 update 事件（包含 description 字段）。
    final itemRow = await (db.select(db.learningItems)
          ..where((t) => t.id.equals(learningItemId)))
        .getSingleOrNull();
    if (itemRow != null) {
      final origin = await sync.resolveOriginKey(
        entityType: 'learning_item',
        localEntityId: learningItemId,
        appliedAtMs: ts,
      );
      await sync.logEvent(
        origin: origin,
        entityType: 'learning_item',
        operation: 'update',
        data: {
          'title': itemRow.title,
          'description': itemRow.description,
          'note': itemRow.note,
          'tags': _parseTags(itemRow.tags),
          'learning_date': itemRow.learningDate.toIso8601String(),
          'created_at': itemRow.createdAt.toIso8601String(),
          'updated_at': (itemRow.updatedAt ?? itemRow.createdAt).toIso8601String(),
          'is_deleted': itemRow.isDeleted,
          'deleted_at': itemRow.deletedAt?.toIso8601String(),
          'is_mock_data': itemRow.isMockData,
        },
        timestampMs: ts,
      );
    }

    // 2) learning_subtasks：为插入的子任务写入 create 事件。
    if (insertedSubtaskIds.isEmpty) return;

    final learningOrigin = await sync.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: learningItemId,
      appliedAtMs: ts,
    );

    for (final id in insertedSubtaskIds) {
      final subtask = await (db.select(db.learningSubtasks)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (subtask == null) continue;

      final origin = await sync.resolveOriginKey(
        entityType: 'learning_subtask',
        localEntityId: id,
        appliedAtMs: ts,
      );
      await sync.logEvent(
        origin: origin,
        entityType: 'learning_subtask',
        operation: 'create',
        data: {
          'uuid': subtask.uuid,
          'learning_origin_device_id': learningOrigin.deviceId,
          'learning_origin_entity_id': learningOrigin.entityId,
          'content': subtask.content,
          'sort_order': subtask.sortOrder,
          'created_at': subtask.createdAt.toIso8601String(),
          'updated_at': (subtask.updatedAt ?? subtask.createdAt).toIso8601String(),
          'is_mock_data': subtask.isMockData,
        },
        timestampMs: ts,
      );
    }
  }

  List<String> _parseTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
