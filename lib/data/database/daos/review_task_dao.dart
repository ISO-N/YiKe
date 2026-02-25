/// 文件用途：ReviewTaskDao - 复习任务数据库访问封装（Drift）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:drift/drift.dart';

import '../../models/review_task_with_item_model.dart';
import '../database.dart';

/// 复习任务 DAO。
///
/// 说明：封装复习任务相关的 CRUD、状态更新及常用查询（今日/逾期/统计等）。
class ReviewTaskDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例。
  /// 异常：无。
  ReviewTaskDao(this.db);

  final AppDatabase db;

  /// 插入复习任务。
  ///
  /// 返回值：新记录 ID。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<int> insertReviewTask(ReviewTasksCompanion companion) {
    return db.into(db.reviewTasks).insert(companion);
  }

  /// 批量插入复习任务。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<void> insertReviewTasks(List<ReviewTasksCompanion> companions) async {
    await db.batch((batch) {
      batch.insertAll(db.reviewTasks, companions);
    });
  }

  /// 更新复习任务。
  ///
  /// 返回值：是否更新成功。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<bool> updateReviewTask(ReviewTask task) {
    return db.update(db.reviewTasks).replace(task);
  }

  /// 更新任务状态。
  ///
  /// 参数：
  /// - [id] 任务 ID
  /// - [status] 状态（pending/done/skipped）
  /// - [completedAt] 完成时间（done 时建议传入）
  /// - [skippedAt] 跳过时间（skipped 时建议传入）
  /// 返回值：更新行数。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<int> updateTaskStatus(
    int id,
    String status, {
    DateTime? completedAt,
    DateTime? skippedAt,
  }) {
    return (db.update(db.reviewTasks)..where((t) => t.id.equals(id))).write(
      ReviewTasksCompanion(
        status: Value(status),
        completedAt: Value(completedAt),
        skippedAt: Value(skippedAt),
      ),
    );
  }

  /// 批量更新任务状态。
  ///
  /// 参数：
  /// - [ids] 任务 ID 列表
  /// - [status] 目标状态
  /// - [timestamp] 对应状态的时间戳（done 使用 completedAt，skipped 使用 skippedAt）
  /// 返回值：更新行数。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<int> updateTaskStatusBatch(
    List<int> ids,
    String status, {
    DateTime? timestamp,
  }) {
    if (ids.isEmpty) return Future.value(0);

    final companion = ReviewTasksCompanion(
      status: Value(status),
      completedAt: Value(status == 'done' ? timestamp : null),
      skippedAt: Value(status == 'skipped' ? timestamp : null),
    );

    return (db.update(db.reviewTasks)..where((t) => t.id.isIn(ids))).write(companion);
  }

  /// 根据 ID 查询复习任务。
  ///
  /// 返回值：复习任务或 null。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<ReviewTask?> getReviewTaskById(int id) {
    return (db.select(db.reviewTasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 查询指定日期的所有复习任务（包含完成/跳过）。
  ///
  /// 参数：
  /// - [date] 目标日期（按年月日）。
  /// 返回值：任务列表（按 scheduledDate 升序）。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<ReviewTask>> getTasksByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (db.select(db.reviewTasks)
          ..where((t) => t.scheduledDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  /// 查询指定日期的所有复习任务（join 学习内容，用于展示/小组件）。
  ///
  /// 说明：包含 pending/done/skipped。
  Future<List<ReviewTaskWithItemModel>> getTasksByDateWithItem(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final task = db.reviewTasks;
    final item = db.learningItems;

    final query = db.select(task).join([
      innerJoin(item, item.id.equalsExp(task.learningItemId)),
    ])
      ..where(task.scheduledDate.isBetweenValues(start, end))
      ..orderBy([
        OrderingTerm.asc(task.status),
        OrderingTerm.asc(task.reviewRound),
      ]);

    final rows = await query.get();
    return rows
        .map(
          (row) => ReviewTaskWithItemModel(
            task: row.readTable(task),
            item: row.readTable(item),
          ),
        )
        .toList();
  }

  /// 查询今日待复习任务（pending，scheduledDate=今日）。
  Future<List<ReviewTaskWithItemModel>> getTodayPendingTasksWithItem() {
    return _getTasksWithItem(
      date: DateTime.now(),
      onlyPending: true,
      onlyOverdue: false,
    );
  }

  /// 查询逾期任务（pending，scheduledDate < 今日）。
  Future<List<ReviewTaskWithItemModel>> getOverdueTasksWithItem() {
    return _getTasksWithItem(
      date: DateTime.now(),
      onlyPending: true,
      onlyOverdue: true,
    );
  }

  /// 查询学习内容关联的所有复习任务。
  Future<List<ReviewTask>> getTasksByLearningItemId(int learningItemId) {
    return (db.select(db.reviewTasks)..where((t) => t.learningItemId.equals(learningItemId))).get();
  }

  /// 获取指定日期任务统计（completed/total）。
  ///
  /// 说明：total 包含 done/skipped/pending，completed 仅统计 done。
  Future<(int completed, int total)> getTaskStats(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final totalExp = db.reviewTasks.id.count();
    final completedExp = db.reviewTasks.id.count(filter: db.reviewTasks.status.equals('done'));

    final row = await (db.selectOnly(db.reviewTasks)
          ..addColumns([totalExp, completedExp])
          ..where(db.reviewTasks.scheduledDate.isBetweenValues(start, end)))
        .getSingle();

    final total = row.read(totalExp) ?? 0;
    final completed = row.read(completedExp) ?? 0;
    return (completed, total);
  }

  Future<List<ReviewTaskWithItemModel>> _getTasksWithItem({
    required DateTime date,
    required bool onlyPending,
    required bool onlyOverdue,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final task = db.reviewTasks;
    final item = db.learningItems;

    final query = db.select(task).join([
      innerJoin(item, item.id.equalsExp(task.learningItemId)),
    ]);

    if (onlyOverdue) {
      query.where(task.scheduledDate.isSmallerThanValue(start));
    } else {
      query.where(task.scheduledDate.isBetweenValues(start, end));
    }

    if (onlyPending) {
      query.where(task.status.equals('pending'));
    }

    query.orderBy([OrderingTerm.asc(task.scheduledDate), OrderingTerm.asc(task.reviewRound)]);

    final rows = await query.get();
    return rows
        .map(
          (row) => ReviewTaskWithItemModel(
            task: row.readTable(task),
            item: row.readTable(item),
          ),
        )
        .toList();
  }
}
