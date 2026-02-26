/// 文件用途：LearningTemplateDao - 学习模板数据库访问封装（Drift），用于快速模板（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 学习模板 DAO。
///
/// 说明：提供模板的 CRUD、排序更新等操作。
class LearningTemplateDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例。
  /// 异常：无。
  LearningTemplateDao(this.db);

  final AppDatabase db;

  /// 插入模板。
  ///
  /// 返回值：新记录 ID。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<int> insertTemplate(LearningTemplatesCompanion companion) {
    return db.into(db.learningTemplates).insert(companion);
  }

  /// 更新模板。
  ///
  /// 返回值：是否更新成功。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<bool> updateTemplate(LearningTemplate row) {
    return db.update(db.learningTemplates).replace(row);
  }

  /// 删除模板。
  ///
  /// 返回值：删除行数。
  /// 异常：数据库删除失败时可能抛出异常。
  Future<int> deleteTemplate(int id) {
    return (db.delete(
      db.learningTemplates,
    )..where((t) => t.id.equals(id))).go();
  }

  /// 根据 ID 获取模板。
  Future<LearningTemplate?> getById(int id) {
    return (db.select(
      db.learningTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 获取全部模板（按 sortOrder、createdAt 排序）。
  Future<List<LearningTemplate>> getAll() {
    return (db.select(db.learningTemplates)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .get();
  }

  /// 检查模板名称是否已存在（忽略指定 id）。
  ///
  /// 返回值：是否存在。
  Future<bool> existsName(String name, {int? exceptId}) async {
    final q = db.selectOnly(db.learningTemplates)
      ..addColumns([db.learningTemplates.id.count()])
      ..where(db.learningTemplates.name.equals(name.trim()));
    if (exceptId != null) {
      q.where(db.learningTemplates.id.isNotValue(exceptId));
    }
    final row = await q.getSingle();
    final count = row.read(db.learningTemplates.id.count()) ?? 0;
    return count > 0;
  }

  /// 批量更新排序字段（事务内执行，确保顺序一致）。
  ///
  /// 参数：
  /// - [idToOrder] 模板 id -> sortOrder 映射
  Future<void> updateSortOrders(Map<int, int> idToOrder) async {
    await db.transaction(() async {
      for (final entry in idToOrder.entries) {
        await (db.update(
          db.learningTemplates,
        )..where((t) => t.id.equals(entry.key))).write(
          LearningTemplatesCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}
