/// 文件用途：SyncLogDao - 同步日志表数据库访问封装（Drift），用于增量同步交换（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 同步日志 DAO。
class SyncLogDao {
  SyncLogDao(this.db);

  final AppDatabase db;

  /// 插入单条日志。
  Future<int> insertLog(SyncLogsCompanion companion) {
    return db
        .into(db.syncLogs)
        .insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// 批量插入日志（用于接收端持久化远端事件，支持幂等）。
  Future<void> insertLogs(List<SyncLogsCompanion> companions) async {
    if (companions.isEmpty) return;
    await db.batch((batch) {
      batch.insertAll(db.syncLogs, companions, mode: InsertMode.insertOrIgnore);
    });
  }

  /// 查询自某个时间戳之后的日志。
  ///
  /// 参数：
  /// - [sinceMs] 起始时间戳（不含）
  /// - [excludeDeviceId] 可选：排除某个源设备的事件（避免回声）
  Future<List<SyncLog>> getLogsSince(int sinceMs, {String? excludeDeviceId}) {
    final query = db.select(db.syncLogs)
      ..where((t) => t.timestampMs.isBiggerThanValue(sinceMs))
      ..orderBy([
        (t) => OrderingTerm.asc(t.timestampMs),
        (t) => OrderingTerm.asc(t.id),
      ]);

    if (excludeDeviceId != null) {
      query.where((t) => t.deviceId.isNotIn([excludeDeviceId]));
    }

    return query.get();
  }

  /// 查询某个源设备自某个时间戳之后的日志（用于发送端构建增量包）。
  Future<List<SyncLog>> getLogsFromDeviceSince(String deviceId, int sinceMs) {
    return (db.select(db.syncLogs)
          ..where(
            (t) =>
                t.deviceId.equals(deviceId) &
                t.timestampMs.isBiggerThanValue(sinceMs),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.timestampMs),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// 删除早于某个时间戳的日志（用于体积控制）。
  Future<int> deleteBefore(int thresholdMs) {
    return (db.delete(
      db.syncLogs,
    )..where((t) => t.timestampMs.isSmallerOrEqualValue(thresholdMs))).go();
  }
}
