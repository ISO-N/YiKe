/// 文件用途：学习模板仓储实现（LearningTemplateRepositoryImpl），用于快速模板（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/learning_template.dart';
import '../../domain/repositories/learning_template_repository.dart';
import '../database/daos/learning_template_dao.dart';
import '../database/database.dart';
import '../sync/sync_log_writer.dart';

/// 学习模板仓储实现。
class LearningTemplateRepositoryImpl implements LearningTemplateRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 模板 DAO。
  /// 异常：无。
  LearningTemplateRepositoryImpl(this.dao, {SyncLogWriter? syncLogWriter})
    : _sync = syncLogWriter;

  final LearningTemplateDao dao;
  final SyncLogWriter? _sync;

  static const Uuid _uuid = Uuid();

  @override
  Future<LearningTemplateEntity> create(LearningTemplateEntity template) async {
    final now = DateTime.now();
    final ensuredUuid =
        template.uuid.trim().isEmpty ? _uuid.v4() : template.uuid.trim();
    final id = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        uuid: Value(ensuredUuid),
        name: template.name.trim(),
        titlePattern: template.titlePattern,
        notePattern: template.notePattern == null
            ? const Value.absent()
            : Value(template.notePattern),
        tags: Value(jsonEncode(template.tags)),
        sortOrder: Value(template.sortOrder),
        createdAt: Value(template.createdAt),
        updatedAt: Value(now),
      ),
    );
    final saved = template.copyWith(id: id, updatedAt: now, uuid: ensuredUuid);

    final sync = _sync;
    if (sync == null) return saved;

    final ts = now.millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'learning_template',
      localEntityId: id,
      appliedAtMs: ts,
    );
    await sync.logEvent(
      origin: origin,
      entityType: 'learning_template',
      operation: 'create',
      data: {
        'name': saved.name,
        'title_pattern': saved.titlePattern,
        'note_pattern': saved.notePattern,
        'tags': saved.tags,
        'sort_order': saved.sortOrder,
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
      entityType: 'learning_template',
      localEntityId: id,
      timestampMs: ts,
    );
    await dao.deleteTemplate(id);
  }

  @override
  Future<List<LearningTemplateEntity>> getAll() async {
    final rows = await dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<LearningTemplateEntity?> getById(int id) async {
    final row = await dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<LearningTemplateEntity> update(LearningTemplateEntity template) async {
    if (template.id == null) {
      throw ArgumentError('更新模板时 id 不能为空');
    }
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final ok = await dao.updateTemplate(
      LearningTemplate(
        id: template.id!,
        uuid: template.uuid,
        name: template.name.trim(),
        titlePattern: template.titlePattern,
        notePattern: template.notePattern,
        tags: jsonEncode(template.tags),
        sortOrder: template.sortOrder,
        createdAt: template.createdAt,
        updatedAt: now,
      ),
    );
    if (!ok) {
      throw StateError('模板更新失败（id=${template.id}）');
    }
    final saved = template.copyWith(updatedAt: now);

    final sync = _sync;
    if (sync == null) return saved;

    final origin = await sync.resolveOriginKey(
      entityType: 'learning_template',
      localEntityId: template.id!,
      appliedAtMs: ts,
    );
    await sync.logEvent(
      origin: origin,
      entityType: 'learning_template',
      operation: 'update',
      data: {
        'name': saved.name,
        'title_pattern': saved.titlePattern,
        'note_pattern': saved.notePattern,
        'tags': saved.tags,
        'sort_order': saved.sortOrder,
        'created_at': saved.createdAt.toIso8601String(),
        'updated_at': (saved.updatedAt ?? saved.createdAt).toIso8601String(),
      },
      timestampMs: ts,
    );

    return saved;
  }

  @override
  Future<bool> existsName(String name, {int? exceptId}) {
    return dao.existsName(name, exceptId: exceptId);
  }

  @override
  Future<void> updateSortOrders(Map<int, int> idToOrder) async {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    await dao.updateSortOrders(idToOrder, now: now);

    final sync = _sync;
    if (sync == null) return;

    // 同步：排序变化属于模板更新的一部分。
    for (final entry in idToOrder.entries) {
      final origin = await sync.resolveOriginKey(
        entityType: 'learning_template',
        localEntityId: entry.key,
        appliedAtMs: ts,
      );
      await sync.logEvent(
        origin: origin,
        entityType: 'learning_template',
        operation: 'update',
        data: {'sort_order': entry.value, 'updated_at': now.toIso8601String()},
        timestampMs: ts,
      );
    }
  }

  LearningTemplateEntity _toEntity(LearningTemplate row) {
    return LearningTemplateEntity(
      id: row.id,
      uuid: row.uuid,
      name: row.name,
      titlePattern: row.titlePattern,
      notePattern: row.notePattern,
      tags: _parseTags(row.tags),
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
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
