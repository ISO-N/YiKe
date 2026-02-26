// 文件用途：LearningTopicRepositoryImpl 单元测试（CRUD、itemIds 聚合、概览查询、异常分支）。
// 作者：Codex
// 创建日期：2026-02-26

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_topic_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_topic_repository_impl.dart';
import 'package:yike/domain/entities/learning_topic.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LearningTopicRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDatabase();
    repo = LearningTopicRepositoryImpl(LearningTopicDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem(String title) {
    return db
        .into(db.learningItems)
        .insert(
          LearningItemsCompanion.insert(
            title: title,
            note: const drift.Value.absent(),
            tags: drift.Value(jsonEncode(<String>[])),
            learningDate: DateTime(2026, 2, 26),
            createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
          ),
        );
  }

  test('create 会写入并回写 id/updatedAt', () async {
    final createdAt = DateTime(2026, 2, 26, 10);
    final input = LearningTopicEntity(
      name: '  Topic  ',
      description: '  desc  ',
      createdAt: createdAt,
    );

    final out = await repo.create(input);
    expect(out.id, isNotNull);
    expect(out.createdAt, createdAt);
    expect(out.updatedAt, isNotNull);
  });

  test('getById / getAll 会附带 itemIds（按关联表 id 升序）', () async {
    final topic = await repo.create(
      LearningTopicEntity(name: 'T', createdAt: DateTime(2026, 2, 26, 10)),
    );

    final item1 = await insertItem('I1');
    final item2 = await insertItem('I2');
    await repo.addItemToTopic(topic.id!, item1);
    await repo.addItemToTopic(topic.id!, item2);

    final byId = await repo.getById(topic.id!);
    expect(byId, isNotNull);
    expect(byId!.itemIds, [item1, item2]);

    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.single.itemIds, [item1, item2]);
  });

  test('removeItemFromTopic: 移除后 itemIds 会变化', () async {
    final topic = await repo.create(
      LearningTopicEntity(name: 'T', createdAt: DateTime(2026, 2, 26)),
    );
    final item = await insertItem('I');
    await repo.addItemToTopic(topic.id!, item);

    await repo.removeItemFromTopic(topic.id!, item);
    final byId = await repo.getById(topic.id!);
    expect(byId, isNotNull);
    expect(byId!.itemIds, isEmpty);
  });

  test('update: id 为空会抛 ArgumentError', () async {
    final entity = LearningTopicEntity(
      name: 'T',
      createdAt: DateTime(2026, 2, 26),
    );
    expect(() => repo.update(entity), throwsArgumentError);
  });

  test('update: 行不存在会抛 StateError', () async {
    final entity = LearningTopicEntity(
      id: 999,
      name: 'T',
      createdAt: DateTime(2026, 2, 26),
    );
    expect(() => repo.update(entity), throwsStateError);
  });

  test('update: 行存在时可成功更新并回写 updatedAt', () async {
    final created = await repo.create(
      LearningTopicEntity(
        name: 'T',
        description: 'd',
        createdAt: DateTime(2026, 2, 26, 10),
      ),
    );

    final updated = await repo.update(created.copyWith(name: 'T2'));
    expect(updated.id, created.id);
    expect(updated.updatedAt, isNotNull);

    final got = await repo.getById(created.id!);
    expect(got, isNotNull);
    expect(got!.name, 'T2');
  });

  test('delete: 删除后 getById 返回 null', () async {
    final created = await repo.create(
      LearningTopicEntity(name: 'T', createdAt: DateTime(2026, 2, 26)),
    );

    await repo.delete(created.id!);
    final got = await repo.getById(created.id!);
    expect(got, isNull);
  });

  test('existsName: 支持 exceptId', () async {
    final a = await repo.create(
      LearningTopicEntity(name: 'A', createdAt: DateTime(2026, 2, 26)),
    );
    expect(await repo.existsName('A'), isTrue);
    expect(await repo.existsName('A', exceptId: a.id), isFalse);
    expect(await repo.existsName('B'), isFalse);
  });

  test('getOverviews: 可返回主题概览并透传聚合字段', () async {
    final topic = await repo.create(
      LearningTopicEntity(name: 'T', createdAt: DateTime(2026, 2, 26)),
    );
    final item = await insertItem('I');
    await repo.addItemToTopic(topic.id!, item);

    // done + pending 两类会影响 total；skipped 不计入。
    await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: item,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 26),
            status: const drift.Value('done'),
          ),
        );
    await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: item,
            reviewRound: 2,
            scheduledDate: DateTime(2026, 2, 26),
            status: const drift.Value('pending'),
          ),
        );
    await db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: item,
            reviewRound: 3,
            scheduledDate: DateTime(2026, 2, 26),
            status: const drift.Value('skipped'),
          ),
        );

    final overviews = await repo.getOverviews();
    expect(overviews.length, 1);
    final o = overviews.single;
    expect(o.topic.id, topic.id);
    expect(o.itemCount, 1);
    expect(o.completedCount, 1);
    expect(o.totalCount, 2);
  });
}
