// 文件用途：ReviewTaskRepositoryImpl 单元测试（创建、查询映射、完成/跳过状态更新）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/review_task_repository_impl.dart';
import 'package:yike/domain/entities/review_task.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ReviewTaskRepositoryImpl repo;
  late ReviewTaskDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = ReviewTaskDao(db);
    repo = ReviewTaskRepositoryImpl(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _insertItemWithTags(String tags) {
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

  test('createBatch 会逐条插入并回写 id', () async {
    final itemId = await _insertItemWithTags(jsonEncode(['a']));
    final base = DateTime(2026, 2, 25);

    final tasks = [
      ReviewTaskEntity(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: ReviewTaskStatus.pending,
        createdAt: base,
      ),
      ReviewTaskEntity(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: base.add(const Duration(days: 1)),
        status: ReviewTaskStatus.pending,
        createdAt: base,
      ),
    ];

    final saved = await repo.createBatch(tasks);
    expect(saved.length, 2);
    expect(saved[0].id, isNotNull);
    expect(saved[1].id, isNotNull);
  });

  test('getTodayPendingTasks 对非法 tags JSON 返回空 tags', () async {
    final itemId = await _insertItemWithTags('not-json');
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

    final views = await repo.getTodayPendingTasks();
    expect(views.length, 1);
    expect(views.single.tags, isEmpty);
  });

  test('completeTask / skipTask 会更新状态与时间戳', () async {
    final itemId = await _insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);
    final taskId = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );

    await repo.completeTask(taskId);
    final done = await dao.getReviewTaskById(taskId);
    expect(done!.status, 'done');
    expect(done.completedAt, isNotNull);

    await repo.skipTask(taskId);
    final skipped = await dao.getReviewTaskById(taskId);
    expect(skipped!.status, 'skipped');
    expect(skipped.skippedAt, isNotNull);
  });
}
