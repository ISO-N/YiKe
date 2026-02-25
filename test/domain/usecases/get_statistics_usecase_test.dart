// 文件用途：GetStatisticsUseCase 单元测试（F7：连续打卡、完成率、标签分布）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_item_dao.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_item_repository_impl.dart';
import 'package:yike/data/repositories/review_task_repository_impl.dart';
import 'package:yike/domain/usecases/get_statistics_usecase.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late GetStatisticsUseCase useCase;

  setUp(() {
    db = createInMemoryDatabase();
    final reviewRepo = ReviewTaskRepositoryImpl(dao: ReviewTaskDao(db));
    final itemRepo = LearningItemRepositoryImpl(LearningItemDao(db));
    useCase = GetStatisticsUseCase(
      reviewTaskRepository: reviewRepo,
      learningItemRepository: itemRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem({required List<String> tags}) {
    return db.into(db.learningItems).insert(
          LearningItemsCompanion.insert(
            title: 'Item',
            note: const drift.Value.absent(),
            tags: drift.Value(jsonEncode(tags)),
            learningDate: DateTime(2026, 2, 1),
            createdAt: drift.Value(DateTime(2026, 2, 1, 9)),
          ),
        );
  }

  test('统计口径：连续打卡 + 本周/本月完成率 + 标签分布', () async {
    final today = DateTime(2026, 2, 25, 12); // 周三
    final itemId1 = await insertItem(tags: ['a', 'b']);
    final itemId2 = await insertItem(tags: ['b']);

    // 连续打卡链：25 done、24 done、23 skipped（不中断）、22 done、21 pending（断签）
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId1,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 25, 9),
            status: const drift.Value('done'),
            completedAt: drift.Value(DateTime(2026, 2, 25, 9)),
            createdAt: drift.Value(DateTime(2026, 2, 25)),
          ),
        );
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId1,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 24, 9),
            status: const drift.Value('done'),
            completedAt: drift.Value(DateTime(2026, 2, 24, 9)),
            createdAt: drift.Value(DateTime(2026, 2, 24)),
          ),
        );
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId2,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 23, 9),
            status: const drift.Value('skipped'),
            skippedAt: drift.Value(DateTime(2026, 2, 23, 9)),
            createdAt: drift.Value(DateTime(2026, 2, 23)),
          ),
        );
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId2,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 22, 9),
            status: const drift.Value('done'),
            completedAt: drift.Value(DateTime(2026, 2, 22, 9)),
            createdAt: drift.Value(DateTime(2026, 2, 22)),
          ),
        );
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId2,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 21, 9),
            status: const drift.Value('pending'),
            createdAt: drift.Value(DateTime(2026, 2, 21)),
          ),
        );

    // 额外插入一条本周 pending（用于完成率分母），以及一条本周 skipped（不计入分母）
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId1,
            reviewRound: 2,
            // 放在“今天之后”，避免影响连续打卡计算；仍落在本周范围内。
            scheduledDate: DateTime(2026, 2, 26, 10),
            status: const drift.Value('pending'),
            createdAt: drift.Value(DateTime(2026, 2, 26)),
          ),
        );
    await db.into(db.reviewTasks).insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId1,
            reviewRound: 2,
            scheduledDate: DateTime(2026, 2, 24, 10),
            status: const drift.Value('skipped'),
            skippedAt: drift.Value(DateTime(2026, 2, 24, 10)),
            createdAt: drift.Value(DateTime(2026, 2, 24)),
          ),
        );

    final result = await useCase.execute(today: today);

    expect(result.consecutiveCompletedDays, 3);

    // 本周范围：2026-02-23(周一) ~ 2026-03-02
    // done: 25、24 => 2
    // pending: 23(10点) => 1
    // skipped 不计入
    expect(result.weekCompleted, 2);
    expect(result.weekTotal, 3);

    // 本月：done 3（25/24/22），pending 2（21/23），skipped 不计入
    expect(result.monthCompleted, 3);
    expect(result.monthTotal, 5);

    expect(result.tagDistribution['a'], 1);
    expect(result.tagDistribution['b'], 2);
  });
}
