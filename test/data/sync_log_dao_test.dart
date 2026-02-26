// 文件用途：SyncLogDao 单元测试（insert/批量 insert/查询过滤/清理历史日志）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/sync_log_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncLogDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = SyncLogDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertLog 支持 insertOrIgnore（同 unique key 重复写入会被忽略）', () async {
    final c = SyncLogsCompanion.insert(
      deviceId: 'd1',
      entityType: 'learning_item',
      entityId: 1,
      operation: 'update',
      data: '{}',
      timestampMs: 100,
    );
    await dao.insertLog(c);
    await dao.insertLog(c);

    final rows = await dao.getLogsSince(0);
    expect(rows, hasLength(1));
  });

  test('insertLogs：空列表直接返回；非空会批量写入', () async {
    await dao.insertLogs(const []);
    expect(await dao.getLogsSince(0), isEmpty);

    await dao.insertLogs([
      SyncLogsCompanion.insert(
        deviceId: 'd1',
        entityType: 'learning_item',
        entityId: 1,
        operation: 'create',
        data: '{"x":1}',
        timestampMs: 101,
      ),
      SyncLogsCompanion.insert(
        deviceId: 'd2',
        entityType: 'learning_item',
        entityId: 2,
        operation: 'create',
        data: '{"x":2}',
        timestampMs: 102,
      ),
    ]);

    expect(await dao.getLogsSince(0), hasLength(2));
  });

  test('getLogsSince 支持排除某个 deviceId', () async {
    await dao.insertLogs([
      SyncLogsCompanion.insert(
        deviceId: 'd1',
        entityType: 'learning_item',
        entityId: 1,
        operation: 'update',
        data: '{}',
        timestampMs: 100,
      ),
      SyncLogsCompanion.insert(
        deviceId: 'd2',
        entityType: 'learning_item',
        entityId: 2,
        operation: 'update',
        data: '{}',
        timestampMs: 101,
      ),
    ]);

    final rows = await dao.getLogsSince(0, excludeDeviceId: 'd1');
    expect(rows, hasLength(1));
    expect(rows.single.deviceId, 'd2');
  });

  test('getLogsFromDeviceSince 仅返回指定设备且按时间排序', () async {
    await dao.insertLogs([
      SyncLogsCompanion.insert(
        deviceId: 'd1',
        entityType: 'x',
        entityId: 1,
        operation: 'update',
        data: '{}',
        timestampMs: 100,
      ),
      SyncLogsCompanion.insert(
        deviceId: 'd1',
        entityType: 'x',
        entityId: 1,
        operation: 'update',
        data: '{}',
        timestampMs: 200,
      ),
      SyncLogsCompanion.insert(
        deviceId: 'd2',
        entityType: 'x',
        entityId: 1,
        operation: 'update',
        data: '{}',
        timestampMs: 150,
      ),
    ]);

    final rows = await dao.getLogsFromDeviceSince('d1', 100);
    expect(rows.map((e) => e.timestampMs).toList(), [200]);
  });

  test('deleteBefore 会删除阈值时间戳及以前的日志', () async {
    await dao.insertLogs([
      SyncLogsCompanion.insert(
        deviceId: 'd1',
        entityType: 'x',
        entityId: 1,
        operation: 'update',
        data: '{}',
        timestampMs: 100,
      ),
      SyncLogsCompanion.insert(
        deviceId: 'd1',
        entityType: 'x',
        entityId: 2,
        operation: 'update',
        data: '{}',
        timestampMs: 200,
      ),
    ]);

    await dao.deleteBefore(100);
    final rows = await dao.getLogsSince(0);
    expect(rows, hasLength(1));
    expect(rows.single.timestampMs, 200);
  });
}

