// 文件用途：LearningItemRepositoryImpl 单元测试（映射、更新异常、非法标签容错）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/learning_item_dao.dart';
import 'package:yike/data/database/daos/sync_entity_mapping_dao.dart';
import 'package:yike/data/database/daos/sync_log_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_item_repository_impl.dart';
import 'package:yike/data/sync/sync_log_writer.dart';
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

  test('update: 学习内容已停用时会抛 StateError', () async {
    final id = await dao.insertLearningItem(
      LearningItemsCompanion.insert(
        title: 'T',
        note: const drift.Value.absent(),
        tags: const drift.Value('[]'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime(2026, 2, 25, 10)),
      ),
    );

    await expectLater(
      () => repo.update(
        LearningItemEntity(
          id: id,
          title: 'T2',
          note: null,
          tags: const [],
          learningDate: DateTime(2026, 2, 25),
          createdAt: DateTime(2026, 2, 25, 9),
          updatedAt: DateTime(2026, 2, 25, 9),
          isDeleted: true,
          deletedAt: DateTime(2026, 2, 25, 10),
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('create/update/delete/updateNote/deactivate 在启用同步写入器时会写入 sync_logs', () async {
    final syncRepo = LearningItemRepositoryImpl(
      dao,
      syncLogWriter: createSyncWriter(),
    );

    final now = DateTime(2026, 2, 25, 10);
    final created = await syncRepo.create(
      LearningItemEntity(
        title: 'T',
        note: null,
        tags: const ['a', 'b'],
        learningDate: DateTime(2026, 2, 25),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await syncRepo.update(created.copyWith(title: 'T2'));
    await syncRepo.updateNote(id: created.id!, note: '  '); // 会归一化为 null
    await syncRepo.deactivate(created.id!);
    await syncRepo.delete(created.id!);

    final logs = await getSyncLogs();
    final operations = logs.map((e) => e.operation).toList();
    expect(operations, contains('create'));
    expect(operations, contains('update'));
    expect(operations, contains('delete'));

    // 额外校验：学习内容 create 的 data 字段应包含 tags（List<String>），避免串行化丢失。
    final createLog = logs.firstWhere(
      (e) => e.entityType == 'learning_item' && e.operation == 'create',
    );
    final data = jsonDecode(createLog.data) as Map<String, dynamic>;
    expect(data['tags'], isA<List<dynamic>>());
  });

  test('Mock 数据不会写入 delete 日志（v3.1）', () async {
    final syncRepo = LearningItemRepositoryImpl(
      dao,
      syncLogWriter: createSyncWriter(),
    );

    final id = await dao.insertLearningItem(
      LearningItemsCompanion.insert(
        title: 'Mock',
        note: const drift.Value.absent(),
        tags: const drift.Value('[]'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
        isMockData: const drift.Value(true),
      ),
    );

    await syncRepo.delete(id);
    final logs = await getSyncLogs();
    expect(logs.where((e) => e.operation == 'delete'), isEmpty);
  });

  test('updateNote: 学习内容不存在/已停用会抛 StateError；重复停用会直接返回', () async {
    final syncRepo = LearningItemRepositoryImpl(
      dao,
      syncLogWriter: createSyncWriter(),
    );

    await expectLater(
      () => syncRepo.updateNote(id: 999, note: 'n'),
      throwsA(isA<StateError>()),
    );

    final id = await dao.insertLearningItem(
      LearningItemsCompanion.insert(
        title: 'T',
        note: const drift.Value.absent(),
        tags: const drift.Value('[]'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime(2026, 2, 25, 10)),
      ),
    );
    await expectLater(
      () => syncRepo.updateNote(id: id, note: 'n'),
      throwsA(isA<StateError>()),
    );

    final active = await syncRepo.create(
      LearningItemEntity(
        title: 'A',
        note: null,
        tags: const [],
        learningDate: DateTime(2026, 2, 25),
        createdAt: DateTime(2026, 2, 25, 9),
        updatedAt: DateTime(2026, 2, 25, 9),
      ),
    );
    await syncRepo.deactivate(active.id!);
    final before = (await getSyncLogs()).length;
    await syncRepo.deactivate(active.id!); // 已停用时直接返回，不应重复写日志
    final after = (await getSyncLogs()).length;
    expect(after, before);
  });

  test('Mock 数据不会写入 update 日志（update/updateNote/deactivate）', () async {
    final syncRepo = LearningItemRepositoryImpl(
      dao,
      syncLogWriter: createSyncWriter(),
    );

    final id = await dao.insertLearningItem(
      LearningItemsCompanion.insert(
        title: 'Mock',
        note: const drift.Value.absent(),
        tags: const drift.Value('[]'),
        learningDate: DateTime(2026, 2, 25),
        createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
        isMockData: const drift.Value(true),
      ),
    );

    await syncRepo.update(
      LearningItemEntity(
        id: id,
        title: 'Mock2',
        note: null,
        tags: const [],
        learningDate: DateTime(2026, 2, 25),
        createdAt: DateTime(2026, 2, 25, 9),
        updatedAt: DateTime(2026, 2, 25, 9),
        isMockData: true,
      ),
    );
    await syncRepo.updateNote(id: id, note: 'n');
    await syncRepo.deactivate(id);

    final row = await dao.getLearningItemById(id);
    expect(row!.title, 'Mock2');
    expect(row.note, 'n');
    expect(row.isDeleted, true);

    final logs = await getSyncLogs();
    expect(logs, isEmpty);
  });
}
