// 文件用途：LearningItemRepositoryImpl 单元测试（映射、更新异常、非法标签容错）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_item_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_item_repository_impl.dart';
import 'package:yike/domain/entities/learning_item.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LearningItemRepositoryImpl repo;
  late LearningItemDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = LearningItemDao(db);
    repo = LearningItemRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  test('create 会写入并回写 id/updatedAt', () async {
    final now = DateTime(2026, 2, 25, 10);
    final item = LearningItemEntity(
      title: 'T',
      note: null,
      tags: const ['a'],
      learningDate: DateTime(2026, 2, 25),
      createdAt: now,
      updatedAt: now,
    );

    final saved = await repo.create(item);
    expect(saved.id, isNotNull);
    expect(saved.title, 'T');
    expect(saved.updatedAt, isNotNull);
  });

  test('update: 行存在时可成功更新并回写 updatedAt', () async {
    final now = DateTime(2026, 2, 25, 10);
    final created = await repo.create(
      LearningItemEntity(
        title: 'T',
        note: null,
        tags: const ['a'],
        learningDate: DateTime(2026, 2, 25),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final updated = await repo.update(created.copyWith(title: 'T2'));
    expect(updated.title, 'T2');
    expect(updated.updatedAt, isNotNull);

    final row = await dao.getLearningItemById(updated.id!);
    expect(row!.title, 'T2');
  });

  test('delete: 删除后 getById 返回 null', () async {
    final now = DateTime(2026, 2, 25, 10);
    final created = await repo.create(
      LearningItemEntity(
        title: 'T',
        note: null,
        tags: const [],
        learningDate: DateTime(2026, 2, 25),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repo.delete(created.id!);
    expect(await repo.getById(created.id!), null);
  });

  test('update: id 为空会抛 ArgumentError', () async {
    final now = DateTime(2026, 2, 25, 10);
    final item = LearningItemEntity(
      id: null,
      title: 'T',
      note: null,
      tags: const [],
      learningDate: DateTime(2026, 2, 25),
      createdAt: now,
      updatedAt: now,
    );

    expect(() => repo.update(item), throwsArgumentError);
  });

  test('update: 行不存在会抛 StateError', () async {
    final now = DateTime(2026, 2, 25, 10);
    final item = LearningItemEntity(
      id: 999,
      title: 'T',
      note: null,
      tags: const [],
      learningDate: DateTime(2026, 2, 25),
      createdAt: now,
      updatedAt: now,
    );

    expect(() => repo.update(item), throwsStateError);
  });

  test('getById 对非法 tags JSON 返回空列表', () async {
    final id = await dao.insertLearningItem(
      LearningItemsCompanion.insert(
        title: 'T',
        note: const drift.Value.absent(),
        tags: const drift.Value('not-json'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
      ),
    );

    final got = await repo.getById(id);
    expect(got, isNotNull);
    expect(got!.tags, isEmpty);
  });
}
