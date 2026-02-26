// 文件用途：LearningTemplateDao 单元测试（CRUD、排序、existsName、批量更新 sortOrder）。
// 作者：Codex
// 创建日期：2026-02-26

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_template_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LearningTemplateDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = LearningTemplateDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertTemplate / getById 可正常读写（含 notePattern 可空）', () async {
    final id = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'T1',
        titlePattern: '{date}',
        notePattern: const drift.Value.absent(),
        tags: drift.Value(jsonEncode(['a', 'b'])),
        sortOrder: const drift.Value(2),
        createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
        updatedAt: drift.Value(DateTime(2026, 2, 26, 10)),
      ),
    );

    final row = await dao.getById(id);
    expect(row, isNotNull);
    expect(row!.name, 'T1');
    expect(row.titlePattern, '{date}');
    expect(row.notePattern, isNull);
    expect(row.tags, '["a","b"]');
    expect(row.sortOrder, 2);
  });

  test('getAll 按 sortOrder 升序，其次 createdAt 倒序', () async {
    await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'B',
        titlePattern: 'b',
        tags: const drift.Value('[]'),
        sortOrder: const drift.Value(1),
        createdAt: drift.Value(DateTime(2026, 2, 26, 9)),
      ),
    );
    await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'A2',
        titlePattern: 'a2',
        tags: const drift.Value('[]'),
        sortOrder: const drift.Value(0),
        createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
      ),
    );
    await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'A1',
        titlePattern: 'a1',
        tags: const drift.Value('[]'),
        sortOrder: const drift.Value(0),
        createdAt: drift.Value(DateTime(2026, 2, 26, 8)),
      ),
    );

    final rows = await dao.getAll();
    expect(rows.map((e) => e.name).toList(), ['A2', 'A1', 'B']);
  });

  test('updateTemplate: 行不存在时 replace 返回 false', () async {
    final ok = await dao.updateTemplate(
      LearningTemplate(
        id: 999,
        name: 'X',
        titlePattern: 'x',
        notePattern: null,
        tags: '[]',
        sortOrder: 0,
        createdAt: DateTime(2026, 2, 26),
        updatedAt: DateTime(2026, 2, 26),
      ),
    );
    expect(ok, isFalse);
  });

  test('deleteTemplate: 删除后 getById 返回 null', () async {
    final id = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'T',
        titlePattern: 't',
        tags: const drift.Value('[]'),
        createdAt: drift.Value(DateTime(2026, 2, 26)),
      ),
    );
    await dao.deleteTemplate(id);

    final row = await dao.getById(id);
    expect(row, isNull);
  });

  test('existsName: 支持 exceptId 过滤', () async {
    final id = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'Dup',
        titlePattern: 't',
        tags: const drift.Value('[]'),
        createdAt: drift.Value(DateTime(2026, 2, 26)),
      ),
    );

    expect(await dao.existsName('Dup'), isTrue);
    expect(await dao.existsName('Dup', exceptId: id), isFalse);
    expect(await dao.existsName('NotExists'), isFalse);
  });

  test('updateSortOrders: 可批量更新 sortOrder 并写入 updatedAt', () async {
    final id1 = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'T1',
        titlePattern: 't1',
        tags: const drift.Value('[]'),
        sortOrder: const drift.Value(0),
        createdAt: drift.Value(DateTime(2026, 2, 26, 10)),
      ),
    );
    final id2 = await dao.insertTemplate(
      LearningTemplatesCompanion.insert(
        name: 'T2',
        titlePattern: 't2',
        tags: const drift.Value('[]'),
        sortOrder: const drift.Value(1),
        createdAt: drift.Value(DateTime(2026, 2, 26, 11)),
      ),
    );

    await dao.updateSortOrders({id1: 5, id2: 2});

    final rows = await dao.getAll();
    expect(rows.map((e) => e.id).toList(), [id2, id1]);
    final row1 = await dao.getById(id1);
    final row2 = await dao.getById(id2);
    expect(row1!.sortOrder, 5);
    expect(row2!.sortOrder, 2);
    expect(row1.updatedAt, isNotNull);
    expect(row2.updatedAt, isNotNull);
  });
}
