/// 文件用途：同步日志写入器（F12）——供数据层仓储复用，用于：
/// 1) 解析“本地实体”对应的 origin key（支持跨设备映射）
/// 2) 写入 sync_logs 作为增量同步事件
/// 3) 维护 sync_entity_mappings 的 lastAppliedAtMs / tombstone
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/daos/sync_entity_mapping_dao.dart';
import '../database/daos/sync_log_dao.dart';
import '../database/database.dart';

/// origin key：用于在多设备之间定位“同一逻辑实体”。
class OriginKey {
  const OriginKey({required this.deviceId, required this.entityId});

  final String deviceId;
  final int entityId;
}

/// 同步日志写入器。
class SyncLogWriter {
  SyncLogWriter({
    required this.syncLogDao,
    required this.syncEntityMappingDao,
    required this.localDeviceId,
  });

  final SyncLogDao syncLogDao;
  final SyncEntityMappingDao syncEntityMappingDao;
  final String localDeviceId;

  /// 解析“本地实体”对应的 origin key。
  ///
  /// 说明：
  /// - 若本地尚无映射，则创建“本机 origin 映射”（originDeviceId=localDeviceId，originEntityId=localEntityId）
  /// - 若本地已有映射（来自其他设备的记录），则返回其 origin key
  Future<OriginKey> resolveOriginKey({
    required String entityType,
    required int localEntityId,
    required int appliedAtMs,
  }) async {
    final mapping = await syncEntityMappingDao.getByLocalEntityId(
      entityType: entityType,
      localEntityId: localEntityId,
    );

    if (mapping != null) {
      await _touchMapping(
        entityType: mapping.entityType,
        originDeviceId: mapping.originDeviceId,
        originEntityId: mapping.originEntityId,
        localEntityId: mapping.localEntityId,
        appliedAtMs: appliedAtMs,
        isDeleted: false,
      );
      return OriginKey(
        deviceId: mapping.originDeviceId,
        entityId: mapping.originEntityId,
      );
    }

    await _touchMapping(
      entityType: entityType,
      originDeviceId: localDeviceId,
      originEntityId: localEntityId,
      localEntityId: localEntityId,
      appliedAtMs: appliedAtMs,
      isDeleted: false,
    );
    return OriginKey(deviceId: localDeviceId, entityId: localEntityId);
  }

  /// 记录 create/update/delete 事件（幂等：由 SyncLogs uniqueKeys 保障）。
  Future<void> logEvent({
    required OriginKey origin,
    required String entityType,
    required String operation,
    required Map<String, dynamic> data,
    required int timestampMs,
  }) async {
    await syncLogDao.insertLog(
      SyncLogsCompanion(
        deviceId: Value(origin.deviceId),
        entityType: Value(entityType),
        entityId: Value(origin.entityId),
        operation: Value(operation),
        data: Value(jsonEncode(data)),
        timestampMs: Value(timestampMs),
        localVersion: const Value(0),
      ),
    );
  }

  /// 标记实体已删除（tombstone），并写入 delete 日志。
  Future<void> logDelete({
    required String entityType,
    required int localEntityId,
    required int timestampMs,
  }) async {
    final origin = await resolveOriginKey(
      entityType: entityType,
      localEntityId: localEntityId,
      appliedAtMs: timestampMs,
    );

    await _touchMapping(
      entityType: entityType,
      originDeviceId: origin.deviceId,
      originEntityId: origin.entityId,
      localEntityId: localEntityId,
      appliedAtMs: timestampMs,
      isDeleted: true,
    );

    await logEvent(
      origin: origin,
      entityType: entityType,
      operation: 'delete',
      data: const {},
      timestampMs: timestampMs,
    );
  }

  Future<void> _touchMapping({
    required String entityType,
    required String originDeviceId,
    required int originEntityId,
    required int localEntityId,
    required int appliedAtMs,
    required bool isDeleted,
  }) async {
    await syncEntityMappingDao.upsertMapping(
      SyncEntityMappingsCompanion(
        entityType: Value(entityType),
        originDeviceId: Value(originDeviceId),
        originEntityId: Value(originEntityId),
        localEntityId: Value(localEntityId),
        lastAppliedAtMs: Value(appliedAtMs),
        isDeleted: Value(isDeleted),
      ),
    );
  }
}
