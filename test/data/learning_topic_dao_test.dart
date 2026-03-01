// 文件用途：LearningTopicDao 单元测试（CRUD、关联管理、概览统计、existsName）。
// 作者：Codex
// 创建日期：2026-02-26

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_topic_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';
import '../helpers/test_uuid.dart';

void main() {
  late AppDatabase db;
  late LearningTopicDao dao;
  var uuidSeed = 1;

  setUp(() {
    db = createInMemoryDatabase();
    dao = LearningTopicDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem(String title) {
    return db
        .into(db.learningItems)
        .insert(
          LearningItemsCompanion.insert(
            uuid: drift.Value(testUuid(uuidSeed++)),
            title: title,
            note: const drift.Value.absent(),
            tags: drift.Value(jsonEncode(<String>[])),
            learningDate: DateTime(2026, 2, 26),
            createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
          ),
        );
  }

  test('insertTopic / getById 可正常读写', () async {
    final id = await dao.insertTopic(
      LearningTopicsCompanion.insert(
        uuid: drift.Value(testUuid(uuidSeed++)),
        name: 'Topic1',
        description: const drift.Value('desc'),
        createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
        updatedAt: drift.Value(DateTime(2026, 2, 26, 10)),
      ),
    );

    final row = await dao.getById(id);
    expect(row, isNotNull);
    expect(row!.name, 'Topic1');
    expect(row.description, 'desc');
  });

  test('getAllTopics 按 createdAt 倒序', () async {
    await dao.insertTopic(
      LearningTopicsCompanion.insert(
        uuid: drift.Value(testUuid(uuidSeed++)),
        name: 'Old',
        createdAt: drift.Value(DateTime(2026, 2, 26, 9)),
      ),
    );
    await dao.insertTopic(
      LearningTopicsCompanion.insert(
        uuid: drift.Value(testUuid(uuidSeed++)),
        name: 'New',
        createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
      ),
    );

    final rows = await dao.getAllTopics();
    expect(rows.map((e) => e.name).toList(), ['New', 'Old']);
  });

  test(
    'addItemToTopic / getItemIdsByTopicId / removeItemFromTopic 可正常工作且去重',
    () async {
      final topicId = await dao.insertTopic(
        LearningTopicsCompanion.insert(
          uuid: drift.Value(testUuid(uuidSeed++)),
          name: 'T',
          createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
        ),
      );
      final item1 = await insertItem('I1');
      final item2 = await insertItem('I2');

      await dao.addItemToTopic(topicId, item1);
      await dao.addItemToTopic(topicId, item2);
      await dao.addItemToTopic(topicId, item1); // 重复关联应被 insertOrIgnore 忽略

      final ids = await dao.getItemIdsByTopicId(topicId);
      expect(ids, [item1, item2]);

      final removed = await dao.removeItemFromTopic(topicId, item1);
      expect(removed, 1);
      final after = await dao.getItemIdsByTopicId(topicId);
      expect(after, [item2]);
    },
  );

  test('existsName: 支持 exceptId 过滤', () async {
    final id = await dao.insertTopic(
      LearningTopicsCompanion.insert(
        uuid: drift.Value(testUuid(uuidSeed++)),
        name: 'Dup',
        createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
      ),
    );

    expect(await dao.existsName('Dup'), isTrue);
    expect(await dao.existsName('Dup', exceptId: id), isFalse);
    expect(await dao.existsName('NotExists'), isFalse);
  });

  test(
    'getTopicOverviews: itemCount 去重，done/pending 计入 total，skipped 不计入',
    () async {
      final topic1 = await dao.insertTopic(
        LearningTopicsCompanion.insert(
          uuid: drift.Value(testUuid(uuidSeed++)),
          name: 'T1',
          createdAt: drift.Value(DateTime(2026, 2, 26, 9)),
        ),
      );
      final topic2 = await dao.insertTopic(
        LearningTopicsCompanion.insert(
          uuid: drift.Value(testUuid(uuidSeed++)),
          name: 'T2',
          createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
        ),
      );

      final itemA = await insertItem('A');
      final itemB = await insertItem('B');

      await dao.addItemToTopic(topic1, itemA);
      await dao.addItemToTopic(topic1, itemB);

      // itemA：done + pending + skipped
      await db
          .into(db.reviewTasks)
          .insert(
            ReviewTasksCompanion.insert(
              uuid: drift.Value(testUuid(uuidSeed++)),
              learningItemId: itemA,
              reviewRound: 1,
              scheduledDate: DateTime(2026, 2, 26),
              status: const drift.Value('done'),
            ),
          );
      await db
          .into(db.reviewTasks)
          .insert(
            ReviewTasksCompanion.insert(
              uuid: drift.Value(testUuid(uuidSeed++)),
              learningItemId: itemA,
              reviewRound: 2,
              scheduledDate: DateTime(2026, 2, 26),
              status: const drift.Value('pending'),
            ),
          );
      await db
          .into(db.reviewTasks)
          .insert(
            ReviewTasksCompanion.insert(
              uuid: drift.Value(testUuid(uuidSeed++)),
              learningItemId: itemA,
              reviewRound: 3,
              scheduledDate: DateTime(2026, 2, 26),
              status: const drift.Value('skipped'),
            ),
          );

      // itemB：两条 done
      await db
          .into(db.reviewTasks)
          .insert(
            ReviewTasksCompanion.insert(
              uuid: drift.Value(testUuid(uuidSeed++)),
              learningItemId: itemB,
              reviewRound: 1,
              scheduledDate: DateTime(2026, 2, 26),
              status: const drift.Value('done'),
            ),
          );
      await db
          .into(db.reviewTasks)
          .insert(
            ReviewTasksCompanion.insert(
              uuid: drift.Value(testUuid(uuidSeed++)),
              learningItemId: itemB,
              reviewRound: 2,
              scheduledDate: DateTime(2026, 2, 26),
              status: const drift.Value('done'),
            ),
          );

      final rows = await dao.getTopicOverviews();

      // 说明：与实现保持一致，按 topic.createdAt 倒序。
      expect(rows.map((e) => e.topic.id).toList(), [topic2, topic1]);

      final t2 = rows.firstWhere((e) => e.topic.id == topic2);
      expect(t2.itemCount, 0);
      expect(t2.completedCount, 0);
      expect(t2.totalCount, 0);

      final t1 = rows.firstWhere((e) => e.topic.id == topic1);
      expect(t1.itemCount, 2);
      expect(t1.completedCount, 3); // itemA(done=1) + itemB(done=2)
      expect(t1.totalCount, 4); // itemA(done+pending=2) + itemB(done=2)
    },
  );
}
