/// 文件用途：LearningSubtaskDao - 学习子任务数据库访问封装（Drift）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 学习子任务 DAO。
///
/// 说明：封装子任务的 CRUD、排序与统计（用于列表摘要）。
class LearningSubtaskDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例
  /// 异常：无。
  LearningSubtaskDao(this.db);

  final AppDatabase db;

  /// 按 learningItemId 获取子任务列表（按 sortOrder 升序）。
  Future<List<LearningSubtask>> getByLearningItemId(int learningItemId) {
    return (db.select(db.learningSubtasks)
          ..where((t) => t.learningItemId.equals(learningItemId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// 批量按 learningItemId 获取子任务列表（按 learningItemId + sortOrder 升序）。
  Future<List<LearningSubtask>> getByLearningItemIds(List<int> learningItemIds) {
    if (learningItemIds.isEmpty) return Future.value(const <LearningSubtask>[]);
    return (db.select(db.learningSubtasks)
          ..where((t) => t.learningItemId.isIn(learningItemIds))
          ..orderBy([
            (t) => OrderingTerm.asc(t.learningItemId),
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// 插入子任务。
  ///
  /// 返回值：新记录 ID。
  Future<int> insertSubtask(LearningSubtasksCompanion companion) {
    return db.into(db.learningSubtasks).insert(companion);
  }

  /// 更新子任务。
  ///
  /// 返回值：是否更新成功。
  Future<bool> updateSubtask(LearningSubtask subtask) {
    return db.update(db.learningSubtasks).replace(subtask);
  }

  /// 删除子任务。
  ///
  /// 返回值：删除行数。
  Future<int> deleteSubtask(int id) {
    return (db.delete(db.learningSubtasks)..where((t) => t.id.equals(id))).go();
  }

  /// 删除某学习内容下的全部子任务（用于迁移兜底/覆盖导入）。
  Future<int> deleteByLearningItemId(int learningItemId) {
    return (db.delete(db.learningSubtasks)
          ..where((t) => t.learningItemId.equals(learningItemId)))
        .go();
  }

  /// 批量查询学习内容的子任务数量（用于首页/任务中心/日历摘要）。
  ///
  /// 返回值：Map（key=learningItemId，value=count）。
  Future<Map<int, int>> getCountsByLearningItemIds(List<int> learningItemIds) async {
    if (learningItemIds.isEmpty) return const {};

    final t = db.learningSubtasks;
    final countExp = t.id.count();

    final query = db.selectOnly(t)
      ..addColumns([t.learningItemId, countExp])
      ..where(t.learningItemId.isIn(learningItemIds))
      ..groupBy([t.learningItemId]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(t.learningItemId)!: row.read(countExp) ?? 0,
    };
  }

  /// 调整排序（同一 learningItemId 内）。
  ///
  /// 规则：
  /// - [subtaskIds] 为目标顺序（从 0 开始）
  /// - 会写入 updatedAt，便于同步冲突解决
  Future<void> reorderSubtasks(int learningItemId, List<int> subtaskIds) async {
    if (subtaskIds.isEmpty) return;

    final now = DateTime.now();
    await db.transaction(() async {
      await db.batch((batch) {
        for (var i = 0; i < subtaskIds.length; i++) {
          final id = subtaskIds[i];
          batch.update(
            db.learningSubtasks,
            LearningSubtasksCompanion(
              sortOrder: Value(i),
              updatedAt: Value(now),
            ),
            where: (t) => t.id.equals(id) & t.learningItemId.equals(learningItemId),
          );
        }
      });
    });
  }
}
