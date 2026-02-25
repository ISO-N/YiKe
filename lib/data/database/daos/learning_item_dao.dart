/// 文件用途：LearningItemDao - 学习内容数据库访问封装（Drift）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database.dart';

/// 学习内容 DAO。
///
/// 说明：封装学习内容相关的 CRUD 与查询逻辑。
class LearningItemDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例。
  /// 异常：无。
  LearningItemDao(this.db);

  final AppDatabase db;

  /// 插入学习内容。
  ///
  /// 返回值：新记录 ID。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<int> insertLearningItem(LearningItemsCompanion companion) {
    return db.into(db.learningItems).insert(companion);
  }

  /// 更新学习内容。
  ///
  /// 返回值：是否更新成功。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<bool> updateLearningItem(LearningItem item) {
    return db.update(db.learningItems).replace(item);
  }

  /// 删除学习内容（级联删除关联复习任务）。
  ///
  /// 返回值：删除行数。
  /// 异常：数据库删除失败时可能抛出异常。
  Future<int> deleteLearningItem(int id) {
    return (db.delete(db.learningItems)..where((t) => t.id.equals(id))).go();
  }

  /// 根据 ID 查询学习内容。
  ///
  /// 返回值：学习内容或 null。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<LearningItem?> getLearningItemById(int id) {
    return (db.select(db.learningItems)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 查询所有学习内容（按创建时间倒序）。
  ///
  /// 返回值：学习内容列表。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<LearningItem>> getAllLearningItems() {
    return (db.select(db.learningItems)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// 根据日期查询学习内容（按学习日期）。
  ///
  /// 参数：
  /// - [date] 目标日期（按年月日）。
  /// 返回值：学习内容列表。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<LearningItem>> getLearningItemsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (db.select(db.learningItems)
          ..where((t) => t.learningDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 根据标签查询学习内容（v1.0 MVP：使用 LIKE 在 JSON 文本中匹配）。
  ///
  /// 参数：
  /// - [tag] 标签名。
  /// 返回值：学习内容列表。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<LearningItem>> getLearningItemsByTag(String tag) {
    // v1.0 MVP：JSON 文本匹配，避免引入复杂的 JSON1 SQL 依赖。
    final pattern = '%"${tag.trim()}"%';
    return (db.select(db.learningItems)
          ..where((t) => t.tags.like(pattern))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 获取所有标签（去重、按字母排序）。
  ///
  /// 返回值：标签列表。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<String>> getAllTags() async {
    final query = db.selectOnly(db.learningItems)..addColumns([db.learningItems.tags]);
    final rows = await query.get();
    final set = <String>{};
    for (final row in rows) {
      final tagsJson = row.read(db.learningItems.tags) ?? '[]';
      set.addAll(_parseTags(tagsJson));
    }
    final list = set.toList()..sort();
    return list;
  }

  /// F7：获取各标签的学习内容数量（用于饼图）。
  ///
  /// 口径：
  /// - 按 learning_items.tags（JSON 数组）聚合
  /// - 多标签的 item 每个标签各计一次
  /// 返回值：Map（key=tag，value=count，不保证排序）。
  Future<Map<String, int>> getTagDistribution() async {
    final query = db.selectOnly(db.learningItems)..addColumns([db.learningItems.tags]);
    final rows = await query.get();
    final map = <String, int>{};
    for (final row in rows) {
      final tagsJson = row.read(db.learningItems.tags) ?? '[]';
      final tags = _parseTags(tagsJson);
      // 避免同一条记录中重复标签导致计数放大。
      for (final tag in tags.toSet()) {
        map[tag] = (map[tag] ?? 0) + 1;
      }
    }
    return map;
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
