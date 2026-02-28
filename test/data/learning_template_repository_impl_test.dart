// 文件用途：LearningTemplateRepositoryImpl 单元测试（CRUD、标签 JSON 容错、异常分支、排序更新透传）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:yike/data/database/daos/learning_template_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_template_repository_impl.dart';
import 'package:yike/domain/entities/learning_template.dart';

import '../helpers/test_database.dart';
import '../helpers/test_uuid.dart';

void main() {
  late AppDatabase db;
  late LearningTemplateRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDatabase();
    repo = LearningTemplateRepositoryImpl(LearningTemplateDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('create 会写入并回写 id/updatedAt', () async {
    final createdAt = DateTime(2026, 2, 26, 10);
    final input = LearningTemplateEntity(
      uuid: testUuid(1),
      name: '  N  ',
      titlePattern: '{date}',
      notePattern: null,
      tags: const ['a', 'b'],
      sortOrder: 1,
      createdAt: createdAt,
    );

    final out = await repo.create(input);
    expect(out.id, isNotNull);
    expect(out.name, '  N  '); // 说明：实体字段不强制 trim；trim 发生在写入侧。
    expect(out.createdAt, createdAt);
    expect(out.updatedAt, isNotNull);
  });

  test('getAll / getById 会正确解析 tags，并对非法 JSON 回退空列表', () async {
    final createdAt = DateTime(2026, 2, 26, 10);
    final a = await repo.create(
      LearningTemplateEntity(
        uuid: testUuid(2),
        name: 'A',
        titlePattern: 'a',
        notePattern: 'n',
        tags: const ['  x  ', '', 'y'],
        createdAt: createdAt,
      ),
    );

    // 手工制造 tags 非法 JSON，用于覆盖容错分支。
    await db
        .update(db.learningTemplates)
        .write(const LearningTemplatesCompanion(tags: drift.Value('not-json')));

    final byId = await repo.getById(a.id!);
    expect(byId, isNotNull);
    expect(byId!.tags, isEmpty);

    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.single.id, a.id);
  });

  test('update: id 为空会抛 ArgumentError', () async {
    final entity = LearningTemplateEntity(
      uuid: testUuid(3),
      name: 'A',
      titlePattern: 'a',
      tags: const [],
      createdAt: DateTime(2026, 2, 26),
    );
    expect(() => repo.update(entity), throwsArgumentError);
  });

  test('update: 行不存在会抛 StateError', () async {
    final entity = LearningTemplateEntity(
      id: 999,
      uuid: testUuid(4),
      name: 'A',
      titlePattern: 'a',
      tags: const [],
      createdAt: DateTime(2026, 2, 26),
    );
    expect(() => repo.update(entity), throwsStateError);
  });

  test('update: 行存在时可成功更新并回写 updatedAt', () async {
    final createdAt = DateTime(2026, 2, 26, 10);
    final created = await repo.create(
      LearningTemplateEntity(
        uuid: testUuid(5),
        name: 'A',
        titlePattern: 'a',
        tags: const ['x'],
        sortOrder: 0,
        createdAt: createdAt,
      ),
    );

    final updated = await repo.update(
      created.copyWith(titlePattern: 'a2', sortOrder: 2),
    );
    expect(updated.id, created.id);
    expect(updated.updatedAt, isNotNull);

    final got = await repo.getById(created.id!);
    expect(got, isNotNull);
    expect(got!.titlePattern, 'a2');
    expect(got.sortOrder, 2);
  });

  test('delete: 删除后 getById 返回 null', () async {
    final created = await repo.create(
      LearningTemplateEntity(
        uuid: testUuid(6),
        name: 'A',
        titlePattern: 'a',
        tags: const [],
        createdAt: DateTime(2026, 2, 26),
      ),
    );

    await repo.delete(created.id!);
    final got = await repo.getById(created.id!);
    expect(got, isNull);
  });

  test('existsName / updateSortOrders: 透传到 DAO 并生效', () async {
    final a = await repo.create(
      LearningTemplateEntity(
        uuid: testUuid(7),
        name: 'A',
        titlePattern: 'a',
        tags: const [],
        sortOrder: 1,
        createdAt: DateTime(2026, 2, 26, 10),
      ),
    );
    final b = await repo.create(
      LearningTemplateEntity(
        uuid: testUuid(8),
        name: 'B',
        titlePattern: 'b',
        tags: const [],
        sortOrder: 0,
        createdAt: DateTime(2026, 2, 26, 11),
      ),
    );

    expect(await repo.existsName('A'), isTrue);
    expect(await repo.existsName('A', exceptId: a.id), isFalse);

    await repo.updateSortOrders({a.id!: 0, b.id!: 2});
    final all = await repo.getAll();
    expect(all.map((e) => e.id).toList(), [a.id, b.id]);
  });
}
