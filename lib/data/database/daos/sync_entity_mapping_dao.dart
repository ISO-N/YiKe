/// 文件用途：SyncEntityMappingDao - 同步实体映射表数据库访问封装（Drift），用于跨设备实体定位与幂等（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 同步实体映射 DAO。
class SyncEntityMappingDao {
  SyncEntityMappingDao(this.db);

  final AppDatabase db;

  /// 获取本地实体 ID。
  Future<int?> getLocalEntityId({
    required String entityType,
    required String originDeviceId,
    required int originEntityId,
  }) async {
    final row =
        await (db.select(db.syncEntityMappings)..where(
              (t) =>
                  t.entityType.equals(entityType) &
                  t.originDeviceId.equals(originDeviceId) &
                  t.originEntityId.equals(originEntityId),
            ))
            .getSingleOrNull();
    return row?.localEntityId;
  }

  /// 获取映射记录（用于读取 lastAppliedAtMs/isDeleted）。
  Future<SyncEntityMapping?> getMapping({
    required String entityType,
    required String originDeviceId,
    required int originEntityId,
  }) {
    return (db.select(db.syncEntityMappings)..where(
          (t) =>
              t.entityType.equals(entityType) &
              t.originDeviceId.equals(originDeviceId) &
              t.originEntityId.equals(originEntityId),
        ))
        .getSingleOrNull();
  }

  /// 根据本地实体 ID 查询映射（用于“更新远端实体”时定位 origin）。
  ///
  /// 说明：同一 entityType + localEntityId 理论上只应存在一条映射记录。
  Future<SyncEntityMapping?> getByLocalEntityId({
    required String entityType,
    required int localEntityId,
  }) {
    return (db.select(db.syncEntityMappings)..where(
          (t) =>
              t.entityType.equals(entityType) &
              t.localEntityId.equals(localEntityId),
        ))
        .getSingleOrNull();
  }

  /// 新增或更新映射（幂等）。
  Future<int> upsertMapping(SyncEntityMappingsCompanion companion) {
    return db.into(db.syncEntityMappings).insertOnConflictUpdate(companion);
  }

  /// 标记映射为已删除（tombstone）。
  Future<int> markDeleted({
    required String entityType,
    required String originDeviceId,
    required int originEntityId,
    required int appliedAtMs,
  }) {
    return (db.update(db.syncEntityMappings)..where(
          (t) =>
              t.entityType.equals(entityType) &
              t.originDeviceId.equals(originDeviceId) &
              t.originEntityId.equals(originEntityId),
        ))
        .write(
          SyncEntityMappingsCompanion(
            isDeleted: const Value(true),
            lastAppliedAtMs: Value(appliedAtMs),
          ),
        );
  }
}
