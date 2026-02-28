/// 文件用途：ReviewTaskDao - 复习任务数据库访问封装（Drift）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:drift/drift.dart';

import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/task_day_stats.dart';
import '../../models/review_task_with_item_model.dart';
import '../../models/review_task_timeline_model.dart';
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
    final now = DateTime.now();
    return (db.update(db.reviewTasks)..where((t) => t.id.equals(id))).write(
      ReviewTasksCompanion(
        status: Value(status),
        completedAt: Value(completedAt),
        skippedAt: Value(skippedAt),
        updatedAt: Value(now),
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

    final now = DateTime.now();
    final companion = ReviewTasksCompanion(
      status: Value(status),
      completedAt: Value(status == 'done' ? timestamp : null),
      skippedAt: Value(status == 'skipped' ? timestamp : null),
      updatedAt: Value(now),
    );

    return (db.update(
      db.reviewTasks,
    )..where((t) => t.id.isIn(ids))).write(companion);
  }

  /// 根据 ID 查询复习任务。
  ///
  /// 返回值：复习任务或 null。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<ReviewTask?> getReviewTaskById(int id) {
    return (db.select(
      db.reviewTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
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
  Future<List<ReviewTaskWithItemModel>> getTasksByDateWithItem(
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final task = db.reviewTasks;
    final item = db.learningItems;

    final query =
        db.select(task).join([
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

  /// 查询今日已完成任务（done，completedAt=今日）。
  ///
  /// 说明：按 completedAt 的自然日口径统计，不受 scheduledDate 影响。
  Future<List<ReviewTaskWithItemModel>> getTodayCompletedTasksWithItem({
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final start = YikeDateUtils.atStartOfDay(now);
    final end = start.add(const Duration(days: 1));

    final task = db.reviewTasks;
    final item = db.learningItems;

    final query =
        db.select(task).join([
            innerJoin(item, item.id.equalsExp(task.learningItemId)),
          ])
          ..where(task.status.equals('done'))
          ..where(task.completedAt.isBetweenValues(start, end))
          ..orderBy([
            OrderingTerm.desc(task.completedAt),
            OrderingTerm.desc(task.id),
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

  /// 查询今日已跳过任务（skipped，skippedAt=今日）。
  ///
  /// 说明：按 skippedAt 的自然日口径统计，不受 scheduledDate 影响。
  Future<List<ReviewTaskWithItemModel>> getTodaySkippedTasksWithItem({
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final start = YikeDateUtils.atStartOfDay(now);
    final end = start.add(const Duration(days: 1));

    final task = db.reviewTasks;
    final item = db.learningItems;

    final query =
        db.select(task).join([
            innerJoin(item, item.id.equalsExp(task.learningItemId)),
          ])
          ..where(task.status.equals('skipped'))
          ..where(task.skippedAt.isBetweenValues(start, end))
          ..orderBy([OrderingTerm.desc(task.skippedAt), OrderingTerm.desc(task.id)]);

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

  /// 撤销任务状态（done/skipped → pending）。
  ///
  /// 规则：
  /// - status 设置为 pending
  /// - completedAt/skippedAt 清空（两者都清空，避免历史脏数据影响口径）
  /// 返回值：更新行数。
  Future<int> undoTaskStatus(int id) {
    final now = DateTime.now();
    return (db.update(db.reviewTasks)..where((t) => t.id.equals(id))).write(
      ReviewTasksCompanion(
        status: const Value('pending'),
        completedAt: const Value(null),
        skippedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// 获取全量任务状态计数（用于任务中心筛选栏展示）。
  ///
  /// 返回值：(all, pending, done, skipped)。
  Future<(int all, int pending, int done, int skipped)>
  getGlobalTaskStatusCounts() async {
    final allExp = db.reviewTasks.id.count();
    final pendingExp = db.reviewTasks.id.count(
      filter: db.reviewTasks.status.equals('pending'),
    );
    final doneExp = db.reviewTasks.id.count(
      filter: db.reviewTasks.status.equals('done'),
    );
    final skippedExp = db.reviewTasks.id.count(
      filter: db.reviewTasks.status.equals('skipped'),
    );

    final row =
        await (db.selectOnly(db.reviewTasks)
              ..addColumns([allExp, pendingExp, doneExp, skippedExp]))
            .getSingle();

    return (
      row.read(allExp) ?? 0,
      row.read(pendingExp) ?? 0,
      row.read(doneExp) ?? 0,
      row.read(skippedExp) ?? 0,
    );
  }

  /// 按“发生时间”倒序获取任务时间线分页数据（用于任务中心）。
  ///
  /// 说明：
  /// - pending：occurredAt = scheduled_date
  /// - done：occurredAt = COALESCE(completed_at, scheduled_date)
  /// - skipped：occurredAt = COALESCE(skipped_at, scheduled_date)
  /// - 排序：occurredAt DESC, taskId DESC（稳定排序）
  /// - 游标：下一页取“当前页最后一条”，查询条件为 (occurredAt < cursor) OR (occurredAt = cursor AND taskId < cursorId)
  Future<List<ReviewTaskTimelineModel>> getTaskTimelinePageWithItem({
    String? status,
    DateTime? cursorOccurredAt,
    int? cursorTaskId,
    int limit = 20,
  }) async {
    final where = StringBuffer();
    final variables = <Variable<Object?>>[];

    where.write('1=1');
    if (status != null) {
      where.write(' AND rt.status = ?');
      variables.add(Variable<String>(status));
    }

    const occurredSql = '''
CASE rt.status
  WHEN 'pending' THEN rt.scheduled_date
  WHEN 'done' THEN COALESCE(rt.completed_at, rt.scheduled_date)
  WHEN 'skipped' THEN COALESCE(rt.skipped_at, rt.scheduled_date)
  ELSE rt.scheduled_date
END
''';

    final cursorWhere = StringBuffer();
    final cursorVars = <Variable<Object?>>[];
    if (cursorOccurredAt != null && cursorTaskId != null) {
      cursorWhere.write(
        'WHERE (t.occurred_at < ? OR (t.occurred_at = ? AND t."rt.id" < ?))',
      );
      cursorVars.add(Variable<DateTime>(cursorOccurredAt));
      cursorVars.add(Variable<DateTime>(cursorOccurredAt));
      cursorVars.add(Variable<int>(cursorTaskId));
    }

    final sql = '''
SELECT * FROM (
  SELECT
    rt.id AS "rt.id",
    rt.learning_item_id AS "rt.learning_item_id",
    rt.review_round AS "rt.review_round",
    rt.scheduled_date AS "rt.scheduled_date",
    rt.status AS "rt.status",
    rt.completed_at AS "rt.completed_at",
    rt.skipped_at AS "rt.skipped_at",
    rt.created_at AS "rt.created_at",
    rt.updated_at AS "rt.updated_at",
    rt.is_mock_data AS "rt.is_mock_data",

    li.id AS "li.id",
    li.title AS "li.title",
    li.note AS "li.note",
    li.tags AS "li.tags",
    li.learning_date AS "li.learning_date",
    li.created_at AS "li.created_at",
    li.updated_at AS "li.updated_at",
    li.is_mock_data AS "li.is_mock_data",

    $occurredSql AS occurred_at
  FROM review_tasks rt
  INNER JOIN learning_items li ON li.id = rt.learning_item_id
  WHERE ${where.toString()}
) t
${cursorWhere.toString()}
ORDER BY t.occurred_at DESC, t."rt.id" DESC
LIMIT ?
''';

    final rows =
        await db.customSelect(
          sql,
          variables: [...variables, ...cursorVars, Variable<int>(limit)],
          readsFrom: {db.reviewTasks, db.learningItems},
        ).get();

    return rows
        .map((row) {
          final task = db.reviewTasks.map(row.data, tablePrefix: 'rt');
          final item = db.learningItems.map(row.data, tablePrefix: 'li');
          final occurredAt = row.read<DateTime>('occurred_at')!;
          return ReviewTaskTimelineModel(
            model: ReviewTaskWithItemModel(task: task, item: item),
            occurredAt: occurredAt,
          );
        })
        .toList();
  }

  /// 查询学习内容关联的所有复习任务。
  Future<List<ReviewTask>> getTasksByLearningItemId(int learningItemId) {
    return (db.select(
      db.reviewTasks,
    )..where((t) => t.learningItemId.equals(learningItemId))).get();
  }

  /// 获取指定日期任务统计（completed/total）。
  ///
  /// 说明：total 包含 done/skipped/pending，completed 仅统计 done。
  Future<(int completed, int total)> getTaskStats(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final totalExp = db.reviewTasks.id.count();
    final completedExp = db.reviewTasks.id.count(
      filter: db.reviewTasks.status.equals('done'),
    );

    final row =
        await (db.selectOnly(db.reviewTasks)
              ..addColumns([totalExp, completedExp])
              ..where(db.reviewTasks.scheduledDate.isBetweenValues(start, end)))
            .getSingle();

    final total = row.read(totalExp) ?? 0;
    final completed = row.read(completedExp) ?? 0;
    return (completed, total);
  }

  /// F6：获取指定月份每天的任务统计（用于日历圆点标记）。
  ///
  /// 参数：
  /// - [year] 年份
  /// - [month] 月份（1-12）
  /// 返回值：以当天 00:00 为 key 的统计 Map。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<Map<DateTime, TaskDayStats>> getMonthlyTaskStats(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final query = db.selectOnly(db.reviewTasks)
      ..addColumns([db.reviewTasks.scheduledDate, db.reviewTasks.status])
      ..where(db.reviewTasks.scheduledDate.isBiggerOrEqualValue(start))
      ..where(db.reviewTasks.scheduledDate.isSmallerThanValue(end));

    final rows = await query.get();
    final map = <DateTime, _DayStatsAccumulator>{};
    for (final row in rows) {
      final scheduled = row.read(db.reviewTasks.scheduledDate);
      if (scheduled == null) continue;
      final status = row.read(db.reviewTasks.status) ?? 'pending';
      final day = YikeDateUtils.atStartOfDay(scheduled);
      final stats = map.putIfAbsent(day, _DayStatsAccumulator.new);
      switch (status) {
        case 'done':
          stats.done++;
          break;
        case 'skipped':
          stats.skipped++;
          break;
        case 'pending':
        default:
          stats.pending++;
          break;
      }
    }

    return map.map(
      (day, stats) => MapEntry(
        day,
        TaskDayStats(
          pendingCount: stats.pending,
          doneCount: stats.done,
          skippedCount: stats.skipped,
        ),
      ),
    );
  }

  /// F6：获取指定日期范围的任务列表（join 学习内容）。
  ///
  /// 参数：
  /// - [start] 起始时间（包含）
  /// - [end] 结束时间（不包含）
  /// 返回值：任务列表（按 scheduledDate 升序）。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<List<ReviewTaskWithItemModel>> getTasksInRange(
    DateTime start,
    DateTime end,
  ) async {
    final task = db.reviewTasks;
    final item = db.learningItems;

    final query =
        db.select(task).join([
            innerJoin(item, item.id.equalsExp(task.learningItemId)),
          ])
          ..where(task.scheduledDate.isBiggerOrEqualValue(start))
          ..where(task.scheduledDate.isSmallerThanValue(end))
          ..orderBy([
            OrderingTerm.asc(task.scheduledDate),
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

  /// F7：获取连续打卡天数（从今天往前计算）。
  ///
  /// 口径：
  /// - 连续每天至少完成 1 条任务即算打卡成功（done>=1 记 1 天）
  /// - 某天存在 pending 且 done=0 则断签
  /// - skipped 不计入断签，也不计入完成
  /// - 某天没有任务，不中断打卡链
  Future<int> getConsecutiveCompletedDays({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final todayStart = YikeDateUtils.atStartOfDay(now);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 找到最早的“done/pending”任务日期作为遍历下界，避免无穷回溯。
    final minDateExp = db.reviewTasks.scheduledDate.min();
    final minRow =
        await (db.selectOnly(db.reviewTasks)
              ..addColumns([minDateExp])
              ..where(db.reviewTasks.scheduledDate.isSmallerThanValue(todayEnd))
              ..where(db.reviewTasks.status.isIn(const ['done', 'pending'])))
            .getSingle();

    final earliest = minRow.read(minDateExp);
    if (earliest == null) return 0;
    final earliestStart = YikeDateUtils.atStartOfDay(earliest);

    // 一次性拉取范围内的 done/pending 任务，再在 Dart 侧按天聚合。
    final tasks =
        await (db.select(db.reviewTasks)
              ..where(
                (t) => t.scheduledDate.isBiggerOrEqualValue(earliestStart),
              )
              ..where((t) => t.scheduledDate.isSmallerThanValue(todayEnd))
              ..where((t) => t.status.isIn(const ['done', 'pending'])))
            .get();

    final dayMap = <DateTime, _DayStatsAccumulator>{};
    for (final task in tasks) {
      final day = YikeDateUtils.atStartOfDay(task.scheduledDate);
      final stats = dayMap.putIfAbsent(day, _DayStatsAccumulator.new);
      if (task.status == 'done') {
        stats.done++;
      } else {
        stats.pending++;
      }
    }

    var streak = 0;
    for (
      var cursor = todayStart;
      !cursor.isBefore(earliestStart);
      cursor = cursor.subtract(const Duration(days: 1))
    ) {
      final stats = dayMap[cursor];
      final pending = stats?.pending ?? 0;
      final done = stats?.done ?? 0;

      if (pending > 0 && done == 0) {
        // 当天有待复习但没有完成，断签。
        break;
      }

      if (done > 0) {
        streak++;
      }
    }

    return streak;
  }

  /// F7：获取指定日期范围的完成率口径数据（completed/total）。
  ///
  /// 说明：
  /// - completed：done 数量
  /// - total：done + pending 数量（skipped 不参与）
  Future<(int completed, int total)> getTaskStatsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final totalExp = db.reviewTasks.id.count(
      filter: db.reviewTasks.status.isIn(const ['done', 'pending']),
    );
    final completedExp = db.reviewTasks.id.count(
      filter: db.reviewTasks.status.equals('done'),
    );

    final row =
        await (db.selectOnly(db.reviewTasks)
              ..addColumns([totalExp, completedExp])
              ..where(db.reviewTasks.scheduledDate.isBiggerOrEqualValue(start))
              ..where(db.reviewTasks.scheduledDate.isSmallerThanValue(end)))
            .getSingle();

    final total = row.read(totalExp) ?? 0;
    final completed = row.read(completedExp) ?? 0;
    return (completed, total);
  }

  /// F8：获取全部复习任务（用于数据导出）。
  Future<List<ReviewTask>> getAllTasks() {
    return db.select(db.reviewTasks).get();
  }

  /// 删除所有模拟复习任务（v3.1 Debug）。
  ///
  /// 说明：按 isMockData=true 条件删除。
  /// 返回值：删除行数。
  /// 异常：数据库删除失败时可能抛出异常。
  Future<int> deleteMockReviewTasks() {
    return (db.delete(
      db.reviewTasks,
    )..where((t) => t.isMockData.equals(true))).go();
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

    query.orderBy([
      OrderingTerm.asc(task.scheduledDate),
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
}

class _DayStatsAccumulator {
  int pending = 0;
  int done = 0;
  int skipped = 0;
}
