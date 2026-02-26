/// 文件用途：Drift 表定义 - 同步实体映射表（sync_entity_mappings），用于将“源设备实体”映射到本地实体 ID（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

/// 同步实体映射表。
///
/// 说明：
/// - 本项目现有业务表使用自增 Int 主键，各设备之间无法保证 ID 全局唯一
/// - 通过（originDeviceId, originEntityId, entityType）定位“同一逻辑实体”
/// - localEntityId 为本地数据库中对应记录的主键 ID
/// - lastAppliedAtMs 用于幂等与冲突处理（Last-Write-Wins）
class SyncEntityMappings extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 实体类型（与 SyncLogs.entityType 保持一致）。
  TextColumn get entityType => text()();

  /// 源设备 ID（originDeviceId）。
  TextColumn get originDeviceId => text()();

  /// 源设备实体 ID（originEntityId）。
  IntColumn get originEntityId => integer()();

  /// 本地实体 ID（业务表主键）。
  IntColumn get localEntityId => integer()();

  /// 最近一次已应用事件时间戳（毫秒）。
  IntColumn get lastAppliedAtMs => integer().nullable()();

  /// 是否已被删除（用于 tombstone，避免延迟事件“复活”已删数据）。
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {entityType, originDeviceId, originEntityId},
  ];
}
