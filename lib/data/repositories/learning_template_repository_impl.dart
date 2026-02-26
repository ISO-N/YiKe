/// 文件用途：学习模板仓储实现（LearningTemplateRepositoryImpl），用于快速模板（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/learning_template.dart';
import '../../domain/repositories/learning_template_repository.dart';
import '../database/daos/learning_template_dao.dart';
import '../database/database.dart';

/// 学习模板仓储实现。
class LearningTemplateRepositoryImpl implements LearningTemplateRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 模板 DAO。
  /// 异常：无。
  LearningTemplateRepositoryImpl(this.dao);

  final LearningTemplateDao dao;

  @override
  Future<LearningTemplateEntity> create(LearningTemplateEntity template) async {
    final now = DateTime.now();
    final id = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
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
    return template.copyWith(id: id, updatedAt: now);
  }

  @override
  Future<void> delete(int id) async {
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
    final ok = await dao.updateTemplate(
      LearningTemplate(
        id: template.id!,
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
    return template.copyWith(updatedAt: now);
  }

  @override
  Future<bool> existsName(String name, {int? exceptId}) {
    return dao.existsName(name, exceptId: exceptId);
  }

  @override
  Future<void> updateSortOrders(Map<int, int> idToOrder) {
    return dao.updateSortOrders(idToOrder);
  }

  LearningTemplateEntity _toEntity(LearningTemplate row) {
    return LearningTemplateEntity(
      id: row.id,
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

