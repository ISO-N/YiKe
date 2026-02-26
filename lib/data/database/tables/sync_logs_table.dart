/// 文件用途：Drift 表定义 - 局域网同步日志表（sync_logs），用于记录增量变更并在设备间交换（F12）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

/// 同步日志表。
///
/// 关键设计：
/// - deviceId + entityId 组合表示“源设备上的实体标识”（无需全局自增 ID）
/// - 接收端通过 sync_entity_mappings 将（deviceId, entityId）映射到本地实体 ID
class SyncLogs extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 源设备 ID（同时也是该实体的 originDeviceId）。
  TextColumn get deviceId => text()();

  /// 实体类型：learning_item/review_task/template/topic/topic_item_relation/settings/theme 等。
  TextColumn get entityType => text()();

  /// 源设备上的实体 ID（originEntityId）。
  IntColumn get entityId => integer()();

  /// 操作类型：create/update/delete。
  TextColumn get operation => text()();

  /// JSON 数据（create/update 用于携带字段；delete 可为空 JSON）。
  TextColumn get data => text()();

  /// 事件时间戳（毫秒）。
  IntColumn get timestampMs => integer()();

  /// 本地版本号（预留字段，用于未来更严格的冲突解决策略）。
  IntColumn get localVersion => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {deviceId, entityType, entityId, timestampMs, operation},
  ];
}
