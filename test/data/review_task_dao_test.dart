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

  Future<int> _insertItem({required String tags}) {
    return db.into(db.learningItems).insert(
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
    final itemId = await _insertItem(tags: jsonEncode(['a']));
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
    final itemId = await _insertItem(tags: jsonEncode(['a']));
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
    final itemId = await _insertItem(tags: jsonEncode(['a']));
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
    final itemId = await _insertItem(tags: jsonEncode(['a']));
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
    final updated = await dao.updateTaskStatusBatch([id1, id2], 'done', timestamp: ts);
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
    final itemId = await _insertItem(tags: jsonEncode(['a']));
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
}
