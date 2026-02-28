// 文件用途：MockDataService 单元测试——验证 v1.4 规格（默认 10 轮间隔）下可稳定生成模拟数据。
// 作者：Codex
// 创建日期：2026-02-28

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_item_dao.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/infrastructure/debug/mock_data_service.dart';

import '../../helpers/test_database.dart';

void main() {
  test('generate：可按配置生成学习内容与复习任务（并保证 scheduledDate 落在范围内）', () async {
    // 说明：MockDataService 在非 Debug 模式会直接抛错；该断言用于防止测试环境变更导致的误报。
    expect(kDebugMode, true, reason: '该测试依赖 Debug 模式（kDebugMode=true）');

    final db = createInMemoryDatabase();
    addTearDown(() async => db.close());

    final service = MockDataService(
      db: db,
      learningItemDao: LearningItemDao(db),
      reviewTaskDao: ReviewTaskDao(db),
      random: Random(1),
    );

    final config = MockDataConfig(
      contentCount: 10,
      taskCount: 50,
      daysRange: 30,
      template: MockDataTemplate.englishWords,
    );

    // 使用固定 now，避免“跨天”导致区间断言不稳定。
    final fixedNow = DateTime(2026, 2, 28, 12, 0, 0);
    final result = await service.generate(config, nowOverride: fixedNow);

    expect(result.insertedItemCount, 10);
    expect(result.insertedTaskCount, 50);

    final items = await db.select(db.learningItems).get();
    expect(items.length, 10);
    expect(items.every((e) => e.isMockData), true);

    final tasks = await db.select(db.reviewTasks).get();
    expect(tasks.length, 50);
    expect(tasks.every((e) => e.isMockData), true);

    final todayStart = DateTime(fixedNow.year, fixedNow.month, fixedNow.day);
    final scheduledStart = todayStart.subtract(const Duration(days: 29));
    final scheduledEndExclusive = todayStart.add(const Duration(days: 1));

    for (final t in tasks) {
      expect(t.scheduledDate.isBefore(scheduledEndExclusive), true);
      expect(!t.scheduledDate.isBefore(scheduledStart), true);
      expect(const {'pending', 'done', 'skipped'}.contains(t.status), true);
    }
  });
}
