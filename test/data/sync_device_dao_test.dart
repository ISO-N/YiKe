// 文件用途：SyncDeviceDao 单元测试（增删改查与 watchAll）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/sync_device_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncDeviceDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = SyncDeviceDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert / getByDeviceId / update* / deleteByDeviceId 可正常工作', () async {
    await dao.upsert(
      SyncDevicesCompanion.insert(
        deviceId: 'd1',
        deviceName: 'PC',
        deviceType: 'windows',
      ),
    );

    var row = await dao.getByDeviceId('d1');
    expect(row, isNotNull);
    expect(row!.deviceName, 'PC');
    expect(row.ipAddress, isNull);

    // 再次 upsert 同一 deviceId，应走冲突更新分支而非 UNIQUE 约束失败。
    await dao.upsert(
      SyncDevicesCompanion.insert(
        deviceId: 'd1',
        deviceName: 'PC-2',
        deviceType: 'windows',
      ),
    );
    row = await dao.getByDeviceId('d1');
    expect(row!.deviceName, 'PC-2');

    await dao.updateIp('d1', '192.168.1.2');
    row = await dao.getByDeviceId('d1');
    expect(row!.ipAddress, '192.168.1.2');

    await dao.updateAuthToken('d1', 'token');
    row = await dao.getByDeviceId('d1');
    expect(row!.authToken, 'token');

    await dao.updateLastSyncMs('d1', 1000);
    await dao.updateLastOutgoingMs('d1', 2000);
    await dao.updateLastIncomingMs('d1', 3000);
    row = await dao.getByDeviceId('d1');
    expect(row!.lastSyncMs, 1000);
    expect(row.lastOutgoingMs, 2000);
    expect(row.lastIncomingMs, 3000);

    expect(await dao.getAll(), hasLength(1));
    await dao.deleteByDeviceId('d1');
    expect(await dao.getByDeviceId('d1'), isNull);
  });

  test('watchAll 会在数据变化时发出列表更新', () async {
    // 说明：先插入一条数据再开始监听，避免“订阅建立与写入的竞态”导致首帧直接发出非空列表。
    await dao.upsert(
      SyncDevicesCompanion.insert(
        deviceId: 'd2',
        deviceName: 'Phone',
        deviceType: 'android',
      ),
    );

    final stream = dao.watchAll();
    final future = expectLater(
      stream,
      emitsInOrder([
        isA<List<SyncDevice>>().having((e) => e.length, 'length', 1),
        isA<List<SyncDevice>>().having((e) => e.length, 'length', 2),
      ]),
    );

    await dao.upsert(
      SyncDevicesCompanion.insert(
        deviceId: 'd3',
        deviceName: 'Tablet',
        deviceType: 'android',
      ),
    );

    await future;
  });
}
