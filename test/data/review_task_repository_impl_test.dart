// 文件用途：ReviewTaskRepositoryImpl 单元测试（创建、查询映射、完成/跳过状态更新）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/daos/sync_entity_mapping_dao.dart';
import 'package:yike/data/database/daos/sync_log_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/review_task_repository_impl.dart';
import 'package:yike/data/sync/sync_log_writer.dart';
import 'package:yike/domain/entities/task_timeline.dart';
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

  SyncLogWriter createSyncWriter() {
    return SyncLogWriter(
      syncLogDao: SyncLogDao(db),
      syncEntityMappingDao: SyncEntityMappingDao(db),
      localDeviceId: 'dev-1',
    );
  }

  Future<List<SyncLog>> getSyncLogs() {
    return db.select(db.syncLogs).get();
  }

  Future<int> insertItemWithTags(String tags) {
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

  test('createBatch 会逐条插入并回写 id', () async {
    final itemId = await insertItemWithTags(jsonEncode(['a']));
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
    final itemId = await insertItemWithTags('not-json');
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
    final itemId = await insertItemWithTags(jsonEncode([]));
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

  test('undoTaskStatus 会撤销状态并清空时间戳字段', () async {
    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);
    final taskId = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: const drift.Value('done'),
        completedAt: drift.Value(base.add(const Duration(hours: 9))),
        skippedAt: drift.Value(base.add(const Duration(hours: 10))),
        createdAt: drift.Value(base),
      ),
    );

    await repo.undoTaskStatus(taskId);
    final row = await dao.getReviewTaskById(taskId);
    expect(row!.status, 'pending');
    expect(row.completedAt, null);
    expect(row.skippedAt, null);
  });

  test('getReviewPlan 会返回按 reviewRound 正序的数据', () async {
    final itemId = await insertItemWithTags(jsonEncode(['a']));
    final base = DateTime(2026, 2, 25);

    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: base.add(const Duration(days: 2)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base.add(const Duration(days: 1)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );

    final plan = await repo.getReviewPlan(itemId);
    expect(plan.map((e) => e.reviewRound).toList(), [1, 2]);
  });

  test('adjustReviewDate: 成功更新 scheduledDate；学习内容缺失/已停用会抛 StateError', () async {
    await expectLater(
      () => repo.adjustReviewDate(
        learningItemId: 999,
        reviewRound: 1,
        scheduledDate: DateTime(2026, 2, 28),
      ),
      throwsA(isA<StateError>()),
    );

    final deletedId = await db.into(db.learningItems).insert(
      LearningItemsCompanion.insert(
        title: 'Deleted',
        note: const drift.Value.absent(),
        tags: const drift.Value('[]'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime(2026, 2, 28)),
      ),
    );
    await expectLater(
      () => repo.adjustReviewDate(
        learningItemId: deletedId,
        reviewRound: 1,
        scheduledDate: DateTime(2026, 2, 28),
      ),
      throwsA(isA<StateError>()),
    );

    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );

    final newDate = DateTime(2026, 2, 28);
    await repo.adjustReviewDate(
      learningItemId: itemId,
      reviewRound: 1,
      scheduledDate: newDate,
    );
    final row = await dao.getTaskByLearningItemAndRound(itemId, 1);
    expect(row!.scheduledDate, newDate);
  });

  test('adjustReviewDate: 任务不存在会抛 StateError', () async {
    final itemId = await insertItemWithTags(jsonEncode([]));
    await expectLater(
      () => repo.adjustReviewDate(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: DateTime(2026, 2, 28),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('addReviewRound: 成功创建下一轮任务；到达最大轮次会抛 StateError', () async {
    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);

    // 先放入 1/2 轮任务，并让 round2 为最后日期（用于计算下一轮 date）。
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: base.add(const Duration(days: 2)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );

    await repo.addReviewRound(itemId);
    final round3 = await dao.getTaskByLearningItemAndRound(itemId, 3);
    expect(round3, isNotNull);

    // 插入 round=10，用于触发上限错误分支。
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 10,
        scheduledDate: base.add(const Duration(days: 300)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );
    await expectLater(() => repo.addReviewRound(itemId), throwsA(isA<StateError>()));
  });

  test('addReviewRound: 学习内容不存在/已停用/缺少复习任务均会抛 StateError', () async {
    await expectLater(() => repo.addReviewRound(999), throwsA(isA<StateError>()));

    final deletedId = await db.into(db.learningItems).insert(
      LearningItemsCompanion.insert(
        title: 'Deleted',
        note: const drift.Value.absent(),
        tags: const drift.Value('[]'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime(2026, 2, 28)),
      ),
    );
    await expectLater(() => repo.addReviewRound(deletedId), throwsA(isA<StateError>()));

    final emptyTasksId = await insertItemWithTags(jsonEncode([]));
    await expectLater(
      () => repo.addReviewRound(emptyTasksId),
      throwsA(isA<StateError>()),
    );
  });

  test('getTaskTimelinePage: hasMore=true 时会返回 nextCursor，并可用游标继续分页', () async {
    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 10);

    // occurredAt 依赖 status：pending=scheduledDate。
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base.add(const Duration(hours: 7)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: base.add(const Duration(hours: 8)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );
    await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 3,
        scheduledDate: base.add(const Duration(hours: 9)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
      ),
    );

    final p1 = await repo.getTaskTimelinePage(limit: 2);
    expect(p1.items.length, 2);
    expect(p1.nextCursor, isNotNull);

    final cursor = p1.nextCursor!;
    final p2 = await repo.getTaskTimelinePage(limit: 10, cursor: cursor);
    expect(p2.items.length, 1);
    expect(p2.nextCursor, null);
  });

  test('启用同步写入器时：create/completeTask 会写入 sync_logs（含 update）', () async {
    final syncRepo = ReviewTaskRepositoryImpl(
      dao: dao,
      syncLogWriter: createSyncWriter(),
    );
    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);

    final created = await syncRepo.create(
      ReviewTaskEntity(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: ReviewTaskStatus.pending,
        createdAt: base,
      ),
    );
    await syncRepo.completeTask(created.id!);

    final logs = await getSyncLogs();
    expect(logs.where((e) => e.entityType == 'review_task' && e.operation == 'create'), isNotEmpty);
    expect(logs.where((e) => e.entityType == 'review_task' && e.operation == 'update'), isNotEmpty);
  });

  test('completeTasks / skipTasks 会批量更新并逐条触发同步 update 日志', () async {
    final syncRepo = ReviewTaskRepositoryImpl(
      dao: dao,
      syncLogWriter: createSyncWriter(),
    );
    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);

    final t1 = await syncRepo.create(
      ReviewTaskEntity(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: ReviewTaskStatus.pending,
        createdAt: base,
      ),
    );
    final t2 = await syncRepo.create(
      ReviewTaskEntity(
        learningItemId: itemId,
        reviewRound: 2,
        scheduledDate: base.add(const Duration(days: 1)),
        status: ReviewTaskStatus.pending,
        createdAt: base,
      ),
    );

    await syncRepo.completeTasks([t1.id!, t2.id!]);
    final r1 = await dao.getReviewTaskById(t1.id!);
    final r2 = await dao.getReviewTaskById(t2.id!);
    expect(r1!.status, 'done');
    expect(r2!.status, 'done');

    await syncRepo.skipTasks([t1.id!, t2.id!]);
    final s1 = await dao.getReviewTaskById(t1.id!);
    final s2 = await dao.getReviewTaskById(t2.id!);
    expect(s1!.status, 'skipped');
    expect(s2!.status, 'skipped');

    final logs = await getSyncLogs();
    // 至少包含 2 次 create 与多次 update（complete/skip 各一轮，每条任务都会写 update）。
    expect(
      logs.where((e) => e.entityType == 'review_task' && e.operation == 'update').length,
      greaterThanOrEqualTo(4),
    );
  });

  test('Mock 任务不会写入 update 日志（v3.1）', () async {
    final syncRepo = ReviewTaskRepositoryImpl(
      dao: dao,
      syncLogWriter: createSyncWriter(),
    );
    final itemId = await insertItemWithTags(jsonEncode([]));
    final base = DateTime(2026, 2, 25);

    final taskId = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: itemId,
        reviewRound: 1,
        scheduledDate: base,
        status: const drift.Value('pending'),
        createdAt: drift.Value(base),
        isMockData: const drift.Value(true),
      ),
    );

    await syncRepo.completeTask(taskId);
    final logs = await getSyncLogs();
    expect(logs.where((e) => e.operation == 'update'), isEmpty);
  });

  test('tags JSON 为非 List 时会解析为空 tags（避免 UI 崩溃）', () async {
    final itemId = await insertItemWithTags(jsonEncode({'a': 1}));
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

  test('GetTasksByTimeUseCase 相关实体可正常构造（游标/分页）', () {
    final page = TaskTimelinePageEntity(
      items: const [],
      nextCursor: TaskTimelineCursorEntity(
        occurredAt: DateTime(2026, 2, 28),
        taskId: 1,
      ),
    );
    expect(page.nextCursor!.taskId, 1);
  });
}
