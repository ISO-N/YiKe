/// 文件用途：学习内容仓储实现（LearningItemRepositoryImpl）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/learning_item.dart';
import '../../domain/repositories/learning_item_repository.dart';
import '../database/daos/learning_item_dao.dart';
import '../database/database.dart';

/// 学习内容仓储实现。
class LearningItemRepositoryImpl implements LearningItemRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 学习内容 DAO。
  /// 异常：无。
  LearningItemRepositoryImpl(this.dao);

  final LearningItemDao dao;

  @override
  Future<LearningItemEntity> create(LearningItemEntity item) async {
    final now = DateTime.now();
    final id = await dao.insertLearningItem(
      LearningItemsCompanion.insert(
        title: item.title,
        note: item.note == null ? const Value.absent() : Value(item.note),
        tags: Value(jsonEncode(item.tags)),
        learningDate: item.learningDate,
        createdAt: Value(item.createdAt),
        updatedAt: Value(now),
      ),
    );
    return item.copyWith(id: id, updatedAt: now);
  }

  @override
  Future<void> delete(int id) async {
    await dao.deleteLearningItem(id);
  }

  @override
  Future<List<LearningItemEntity>> getAll() async {
    final rows = await dao.getAllLearningItems();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<LearningItemEntity>> getByDate(DateTime date) async {
    final rows = await dao.getLearningItemsByDate(date);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<LearningItemEntity?> getById(int id) async {
    final row = await dao.getLearningItemById(id);
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<List<LearningItemEntity>> getByTag(String tag) async {
    final rows = await dao.getLearningItemsByTag(tag);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<String>> getAllTags() {
    return dao.getAllTags();
  }

  @override
  Future<Map<String, int>> getTagDistribution() {
    return dao.getTagDistribution();
  }

  @override
  Future<LearningItemEntity> update(LearningItemEntity item) async {
    if (item.id == null) {
      throw ArgumentError('更新学习内容时 id 不能为空');
    }

    final now = DateTime.now();
    final ok = await dao.updateLearningItem(
      LearningItem(
        id: item.id!,
        title: item.title,
        note: item.note,
        tags: jsonEncode(item.tags),
        learningDate: item.learningDate,
        createdAt: item.createdAt,
        updatedAt: now,
      ),
    );
    if (!ok) {
      throw StateError('学习内容更新失败（id=${item.id}）');
    }
    return item.copyWith(updatedAt: now);
  }

  LearningItemEntity _toEntity(LearningItem row) {
    return LearningItemEntity(
      id: row.id,
      title: row.title,
      note: row.note,
      tags: _parseTags(row.tags),
      learningDate: row.learningDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  List<String> _parseTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) {
        return decoded.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
