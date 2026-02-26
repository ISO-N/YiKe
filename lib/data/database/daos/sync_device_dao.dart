/// 文件用途：SyncDeviceDao - 同步设备表数据库访问封装（Drift），用于配对设备持久化（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 同步设备 DAO。
class SyncDeviceDao {
  /// 构造函数。
  SyncDeviceDao(this.db);

  final AppDatabase db;

  /// 获取所有已记录设备。
  Future<List<SyncDevice>> getAll() {
    return db.select(db.syncDevices).get();
  }

  /// 监听设备列表变化（用于 UI 实时刷新）。
  Stream<List<SyncDevice>> watchAll() {
    return db.select(db.syncDevices).watch();
  }

  /// 根据 deviceId 查询设备。
  Future<SyncDevice?> getByDeviceId(String deviceId) {
    return (db.select(
      db.syncDevices,
    )..where((t) => t.deviceId.equals(deviceId))).getSingleOrNull();
  }

  /// 新增或更新设备（按 deviceId 唯一）。
  Future<int> upsert(SyncDevicesCompanion companion) async {
    // 说明：sync_devices 的唯一约束在 deviceId，而 Drift 的 insertOnConflictUpdate
    // 默认只按主键（id）处理冲突，无法覆盖 UNIQUE(device_id) 的场景。
    // 因此这里显式指定冲突目标为 deviceId，实现“按 deviceId upsert”。
    return db
        .into(db.syncDevices)
        .insert(
          companion,
          onConflict: DoUpdate(
            (old) => SyncDevicesCompanion(
              // 仅更新可变字段，避免误改 deviceId。
              deviceName: companion.deviceName,
              deviceType: companion.deviceType,
              ipAddress: companion.ipAddress,
              authToken: companion.authToken,
              isMaster: companion.isMaster,
              lastSyncMs: companion.lastSyncMs,
              lastOutgoingMs: companion.lastOutgoingMs,
              lastIncomingMs: companion.lastIncomingMs,
            ),
            target: [db.syncDevices.deviceId],
          ),
        );
  }

  /// 更新设备 IP。
  Future<int> updateIp(String deviceId, String? ipAddress) {
    return (db.update(db.syncDevices)
          ..where((t) => t.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(ipAddress: Value(ipAddress)));
  }

  /// 更新认证令牌。
  Future<int> updateAuthToken(String deviceId, String? authToken) {
    return (db.update(db.syncDevices)
          ..where((t) => t.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(authToken: Value(authToken)));
  }

  /// 更新最近同步时间戳。
  Future<int> updateLastSyncMs(String deviceId, int? lastSyncMs) {
    return (db.update(db.syncDevices)
          ..where((t) => t.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(lastSyncMs: Value(lastSyncMs)));
  }

  /// 更新发送游标（本地增量 -> 对端）。
  Future<int> updateLastOutgoingMs(String deviceId, int? lastOutgoingMs) {
    return (db.update(db.syncDevices)
          ..where((t) => t.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(lastOutgoingMs: Value(lastOutgoingMs)));
  }

  /// 更新接收游标（对端增量 -> 本地）。
  Future<int> updateLastIncomingMs(String deviceId, int? lastIncomingMs) {
    return (db.update(db.syncDevices)
          ..where((t) => t.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(lastIncomingMs: Value(lastIncomingMs)));
  }

  /// 删除设备记录（断开配对）。
  Future<int> deleteByDeviceId(String deviceId) {
    return (db.delete(
      db.syncDevices,
    )..where((t) => t.deviceId.equals(deviceId))).go();
  }
}
