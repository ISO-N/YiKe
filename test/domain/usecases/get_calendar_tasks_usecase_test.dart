// 文件用途：GetCalendarTasksUseCase 单元测试（F6：月统计 + 当日任务查询）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/review_task_repository_impl.dart';
import 'package:yike/domain/usecases/get_calendar_tasks_usecase.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late GetCalendarTasksUseCase useCase;

  setUp(() {
    db = createInMemoryDatabase();
    final dao = ReviewTaskDao(db);
    final repo = ReviewTaskRepositoryImpl(dao: dao);
    useCase = GetCalendarTasksUseCase(reviewTaskRepository: repo);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem({required List<String> tags}) {
    return db
        .into(db.learningItems)
        .insert(
          LearningItemsCompanion.insert(
            title: 'Item',
            note: const drift.Value.absent(),
            tags: drift.Value(jsonEncode(tags)),
            learningDate: DateTime(2026, 2, 1),
            createdAt: drift.Value(DateTime(2026, 2, 1, 9)),
          ),
        );
  }

  test('execute 返回月份单日统计（pending/done/skipped）', () async {
    final itemId = await insertItem(tags: ['a']);
    final d = DateTime(2026, 2, 10);

    await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 10, 9),
            status: const drift.Value('pending'),
            createdAt: drift.Value(d),
          ),
        );
    await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId,
            reviewRound: 2,
            scheduledDate: DateTime(2026, 2, 10, 10),
            status: const drift.Value('done'),
            completedAt: drift.Value(DateTime(2026, 2, 10, 10)),
            createdAt: drift.Value(d),
          ),
        );

    final result = await useCase.execute(year: 2026, month: 2);
    final stats = result.dayStats[DateTime(2026, 2, 10)];
    expect(stats, isNotNull);
    expect(stats!.pendingCount, 1);
    expect(stats.doneCount, 1);
  });

  test('getTasksByDate 返回当日任务列表（含学习内容字段）', () async {
    final itemId = await insertItem(tags: ['a', 'b']);
    final d = DateTime(2026, 2, 10);

    await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 10, 9),
            status: const drift.Value('pending'),
            createdAt: drift.Value(d),
          ),
        );

    final tasks = await useCase.getTasksByDate(d);
    expect(tasks.length, 1);
    expect(tasks.single.title, 'Item');
    expect(tasks.single.tags, ['a', 'b']);
  });
}
