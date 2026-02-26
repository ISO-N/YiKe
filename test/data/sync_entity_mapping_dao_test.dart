// 文件用途：SyncEntityMappingDao 单元测试（映射查询、upsert 与 tombstone 标记）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:yike/data/database/daos/sync_entity_mapping_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncEntityMappingDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = SyncEntityMappingDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertMapping 后可通过 origin 与 local 两种方式查询', () async {
    await dao.upsertMapping(
      SyncEntityMappingsCompanion.insert(
        entityType: 'learning_item',
        originDeviceId: 'remote',
        originEntityId: 7,
        localEntityId: 100,
        lastAppliedAtMs: const Value(123),
      ),
    );

    expect(
      await dao.getLocalEntityId(
        entityType: 'learning_item',
        originDeviceId: 'remote',
        originEntityId: 7,
      ),
      100,
    );

    final mapping = await dao.getMapping(
      entityType: 'learning_item',
      originDeviceId: 'remote',
      originEntityId: 7,
    );
    expect(mapping, isNotNull);
    expect(mapping!.localEntityId, 100);

    final byLocal = await dao.getByLocalEntityId(
      entityType: 'learning_item',
      localEntityId: 100,
    );
    expect(byLocal, isNotNull);
    expect(byLocal!.originDeviceId, 'remote');
  });

  test('markDeleted 会写入 tombstone 与 lastAppliedAtMs', () async {
    await dao.upsertMapping(
      SyncEntityMappingsCompanion.insert(
        entityType: 'learning_item',
        originDeviceId: 'remote',
        originEntityId: 8,
        localEntityId: 101,
      ),
    );

    await dao.markDeleted(
      entityType: 'learning_item',
      originDeviceId: 'remote',
      originEntityId: 8,
      appliedAtMs: 999,
    );

    final mapping = await dao.getMapping(
      entityType: 'learning_item',
      originDeviceId: 'remote',
      originEntityId: 8,
    );
    expect(mapping, isNotNull);
    expect(mapping!.isDeleted, isTrue);
    expect(mapping.lastAppliedAtMs, 999);
  });
}
