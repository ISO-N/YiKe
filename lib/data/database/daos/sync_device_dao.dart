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
    return db.into(db.syncDevices).insertOnConflictUpdate(companion);
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
