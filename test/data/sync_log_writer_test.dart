// 文件用途：SyncLogWriter 单元测试（origin key 解析、事件写入与 tombstone 处理）。
// 作者：Codex
// 创建日期：2026-02-26

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:yike/data/database/daos/sync_entity_mapping_dao.dart';
import 'package:yike/data/database/daos/sync_log_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/sync/sync_log_writer.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncLogWriter writer;
  late SyncLogDao logDao;
  late SyncEntityMappingDao mappingDao;

  setUp(() {
    db = createInMemoryDatabase();
    logDao = SyncLogDao(db);
    mappingDao = SyncEntityMappingDao(db);
    writer = SyncLogWriter(
      syncLogDao: logDao,
      syncEntityMappingDao: mappingDao,
      localDeviceId: 'local',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('resolveOriginKey：本地无映射时会创建本地 origin 映射', () async {
    final origin = await writer.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: 10,
      appliedAtMs: 123,
    );
    expect(origin.deviceId, 'local');
    expect(origin.entityId, 10);

    final mapping = await mappingDao.getByLocalEntityId(
      entityType: 'learning_item',
      localEntityId: 10,
    );
    expect(mapping, isNotNull);
    expect(mapping!.originDeviceId, 'local');
    expect(mapping.originEntityId, 10);
    expect(mapping.lastAppliedAtMs, 123);
    expect(mapping.isDeleted, isFalse);
  });

  test('resolveOriginKey：已有映射时返回远端 origin，并更新 lastAppliedAtMs', () async {
    await mappingDao.upsertMapping(
      SyncEntityMappingsCompanion.insert(
        entityType: 'learning_item',
        originDeviceId: 'remote',
        originEntityId: 7,
        localEntityId: 11,
        lastAppliedAtMs: const Value(1),
      ),
    );

    final origin = await writer.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: 11,
      appliedAtMs: 999,
    );
    expect(origin.deviceId, 'remote');
    expect(origin.entityId, 7);

    final updated = await mappingDao.getByLocalEntityId(
      entityType: 'learning_item',
      localEntityId: 11,
    );
    expect(updated!.lastAppliedAtMs, 999);
    expect(updated.isDeleted, isFalse);
  });

  test('logEvent 会写入 sync_logs（data 为 JSON 字符串）', () async {
    final origin = await writer.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: 12,
      appliedAtMs: 1000,
    );

    await writer.logEvent(
      origin: origin,
      entityType: 'learning_item',
      operation: 'update',
      data: {'title': 'T'},
      timestampMs: 2000,
    );

    final rows = await logDao.getLogsSince(0);
    expect(rows, hasLength(1));
    expect(rows.single.entityType, 'learning_item');
    expect(rows.single.operation, 'update');
    expect(jsonDecode(rows.single.data), {'title': 'T'});
  });

  test('logDelete 会写入 delete 日志并将 mapping 标记为 tombstone', () async {
    await writer.logDelete(
      entityType: 'learning_item',
      localEntityId: 13,
      timestampMs: 3000,
    );

    final mapping = await mappingDao.getByLocalEntityId(
      entityType: 'learning_item',
      localEntityId: 13,
    );
    expect(mapping, isNotNull);
    expect(mapping!.isDeleted, isTrue);
    expect(mapping.lastAppliedAtMs, 3000);

    final logs = await logDao.getLogsSince(0);
    expect(logs, hasLength(1));
    expect(logs.single.operation, 'delete');
  });
}
