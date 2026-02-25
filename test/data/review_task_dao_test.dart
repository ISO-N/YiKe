// 文件用途：ReviewTaskDao 单元测试（join 查询、今日/逾期筛选、批量状态更新、统计）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ReviewTaskDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = ReviewTaskDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem({required String tags}) {
    return db
        .into(db.learningItems)
        .insert(
          LearningItemsCompanion.insert(
            title: 'Item',
            note: const drift.Value.absent(),
            tags: drift.Value(tags),
            learningDate: DateTime(2026, 2, 25),
            createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
          ),
        );
  }

  test('getTasksByDateWithItem 会 join 并返回模型', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final day = DateTime(2026, 2, 25);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: DateTime(2026, 2, 25, 9),
        status: const drift.Value('pending'),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
      ),
    );

    final rows = await dao.getTasksByDateWithItem(day);
    expect(rows.length, 1);
    expect(rows.single.item.id, itemId);
    expect(rows.single.task.reviewRound, 1);
  });

  test('getTodayPendingTasksWithItem 仅返回今日 pending', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: todayStart.add(const Duration(hours: 9)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(todayStart),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: todayStart.add(const Duration(hours: 10)),
        status: const drift.Value('done'),
        completedAt: drift.Value(todayStart.add(const Duration(hours: 10))),
        createdAt: drift.Value(todayStart),
      ),
    );

    final rows = await dao.getTodayPendingTasksWithItem();
    expect(rows.length, 1);
    expect(rows.single.task.status, 'pending');
  });

  test('getOverdueTasksWithItem 仅返回逾期 pending', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterday = todayStart.subtract(const Duration(days: 1));

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: yesterday.add(const Duration(hours: 9)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(yesterday),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: yesterday.add(const Duration(hours: 10)),
        status: const drift.Value('skipped'),
        skippedAt: drift.Value(yesterday.add(const Duration(hours: 10))),
        createdAt: drift.Value(yesterday),
      ),
    );

    final rows = await dao.getOverdueTasksWithItem();
    expect(rows.length, 1);
    expect(rows.single.task.status, 'pending');
  });

  test('updateTaskStatusBatch 会更新状态与对应时间戳字段', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final base = DateTime(2026, 2, 25);

    final id1 = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );
    final id2 = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: base,
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );

    final ts = DateTime(2026, 2, 25, 12);
    final updated = await dao.updateTaskStatusBatch(
      [id1, id2],
      'done',
      timestamp: ts,
    );
    expect(updated, 2);

    final r1 = await dao.getReviewTaskById(id1);
    final r2 = await dao.getReviewTaskById(id2);
    expect(r1!.status, 'done');
    expect(r1.completedAt, ts);
    expect(r1.skippedAt, null);
    expect(r2!.status, 'done');
    expect(r2.completedAt, ts);
  });

  test('getTaskStats 统计 done/total（total 含 skipped/pending）', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final day = DateTime(2026, 2, 25);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: day.add(const Duration(hours: 9)),
        status: const drift.Value('done'),
        completedAt: drift.Value(day.add(const Duration(hours: 9))),
        createdAt: drift.Value(day),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: day.add(const Duration(hours: 10)),
        status: const drift.Value('skipped'),
        skippedAt: drift.Value(day.add(const Duration(hours: 10))),
        createdAt: drift.Value(day),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 3,
        scheduledDate: day.add(const Duration(hours: 11)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(day),
      ),
    );

    final (completed, total) = await dao.getTaskStats(day);
    expect(completed, 1);
    expect(total, 3);
  });

  test('getMonthlyTaskStats 返回单日 pending/done/skipped 统计', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final d = DateTime(2026, 2, 10);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: d.add(const Duration(hours: 9)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(d),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: d.add(const Duration(hours: 10)),
        status: const drift.Value('done'),
        completedAt: drift.Value(d.add(const Duration(hours: 10))),
        createdAt: drift.Value(d),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 3,
        scheduledDate: d.add(const Duration(hours: 11)),
        status: const drift.Value('skipped'),
        skippedAt: drift.Value(d.add(const Duration(hours: 11))),
        createdAt: drift.Value(d),
      ),
    );

    final stats = await dao.getMonthlyTaskStats(2026, 2);
    final key = DateTime(2026, 2, 10);
    expect(stats.containsKey(key), true);
    expect(stats[key]!.pendingCount, 1);
    expect(stats[key]!.doneCount, 1);
    expect(stats[key]!.skippedCount, 1);
  });

  test('getTasksInRange 按 start 包含、end 不包含返回 join 结果', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final start = DateTime(2026, 2, 10);
    final end = DateTime(2026, 2, 11);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: DateTime(2026, 2, 10, 9),
        status: const drift.Value('pending'),
        createdAt: drift.Value(start),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: DateTime(2026, 2, 11, 0, 0, 0),
        status: const drift.Value('pending'),
        createdAt: drift.Value(end),
      ),
    );

    final rows = await dao.getTasksInRange(start, end);
    expect(rows.length, 1);
    expect(rows.single.item.id, itemId);
    expect(rows.single.task.scheduledDate, DateTime(2026, 2, 10, 9));
  });

  test('getTaskStatsInRange 统计 done/(done+pending)，skipped 不计入', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final start = DateTime(2026, 2, 10);
    final end = DateTime(2026, 2, 11);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: DateTime(2026, 2, 10, 9),
        status: const drift.Value('done'),
        completedAt: drift.Value(DateTime(2026, 2, 10, 9)),
        createdAt: drift.Value(start),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: DateTime(2026, 2, 10, 10),
        status: const drift.Value('pending'),
        createdAt: drift.Value(start),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 3,
        scheduledDate: DateTime(2026, 2, 10, 11),
        status: const drift.Value('skipped'),
        skippedAt: drift.Value(DateTime(2026, 2, 10, 11)),
        createdAt: drift.Value(start),
      ),
    );

    final (completed, total) = await dao.getTaskStatsInRange(start, end);
    expect(completed, 1);
    expect(total, 2);
  });

  test('getConsecutiveCompletedDays 支持“无任务不间断、pending 断签”口径', () async {
    final itemId = await insertItem(tags: jsonEncode(['a']));
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 今天 done（计 1 天）
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: todayStart.add(const Duration(hours: 9)),
        status: const drift.Value('done'),
        completedAt: drift.Value(todayStart.add(const Duration(hours: 9))),
        createdAt: drift.Value(todayStart),
      ),
    );

    // 昨天 done（计 1 天）
    final yesterday = todayStart.subtract(const Duration(days: 1));
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: yesterday.add(const Duration(hours: 9)),
        status: const drift.Value('done'),
        completedAt: drift.Value(yesterday.add(const Duration(hours: 9))),
        createdAt: drift.Value(yesterday),
      ),
    );

    // 前天仅 skipped（不计完成，也不断签）
    final twoDaysAgo = todayStart.subtract(const Duration(days: 2));
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: twoDaysAgo.add(const Duration(hours: 9)),
        status: const drift.Value('skipped'),
        skippedAt: drift.Value(twoDaysAgo.add(const Duration(hours: 9))),
        createdAt: drift.Value(twoDaysAgo),
      ),
    );

    // 大前天 done（计 1 天）
    final threeDaysAgo = todayStart.subtract(const Duration(days: 3));
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: threeDaysAgo.add(const Duration(hours: 9)),
        status: const drift.Value('done'),
        completedAt: drift.Value(threeDaysAgo.add(const Duration(hours: 9))),
        createdAt: drift.Value(threeDaysAgo),
      ),
    );

    // 再往前一天 pending（断签）
    final fourDaysAgo = todayStart.subtract(const Duration(days: 4));
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: fourDaysAgo.add(const Duration(hours: 9)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(fourDaysAgo),
      ),
    );

    final streak = await dao.getConsecutiveCompletedDays(today: now);
    expect(streak, 3);
  });
}
