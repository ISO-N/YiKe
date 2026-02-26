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
    // 说明：sync_entity_mappings 的唯一约束为 (entityType, originDeviceId, originEntityId)，
    // Drift 的 insertOnConflictUpdate 默认只按主键（id）处理冲突，无法覆盖 UNIQUE 约束冲突，
    // 进而在重复写入同一 origin key 时触发 SQLite 2067。
    return db.into(db.syncEntityMappings).insert(
      companion,
      onConflict: DoUpdate(
        (old) => SyncEntityMappingsCompanion(
          // 仅更新会随同步推进而变化的字段。
          localEntityId: companion.localEntityId,
          lastAppliedAtMs: companion.lastAppliedAtMs,
          isDeleted: companion.isDeleted,
        ),
        target: [
          db.syncEntityMappings.entityType,
          db.syncEntityMappings.originDeviceId,
          db.syncEntityMappings.originEntityId,
        ],
      ),
    );
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
