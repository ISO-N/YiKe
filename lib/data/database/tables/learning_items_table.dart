/// 文件用途：Drift 表定义 - 学习内容表（learning_items）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:drift/drift.dart';

/// 学习内容表。
///
/// 说明：存储用户录入的学习内容（标题/备注/标签/学习日期等）。
@TableIndex(name: 'idx_learning_date', columns: {#learningDate})
class LearningItems extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 学习内容标题（必填，≤50字）。
  TextColumn get title => text().withLength(min: 1, max: 50)();

  /// 备注内容（可选，v1.0 MVP 仅纯文本）。
  TextColumn get note => text().nullable()();

  /// 标签列表（JSON 字符串，如 ["Java","英语"]）。
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// 学习日期（首次录入日期，用于生成复习计划）。
  DateTimeColumn get learningDate => dateTime()();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间（可空）。
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// 是否已停用（软删除标记）。
  ///
  /// 说明：
  /// - Drift 字段名：isDeleted
  /// - 数据库列名：is_deleted
  /// - 仅用于“停用学习内容”，查询列表需默认过滤 is_deleted=0
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  /// 停用时间（Unix epoch 毫秒；与 createdAt/updatedAt 保持一致）。
  ///
  /// 说明：
  /// - Drift 字段名：deletedAt
  /// - 数据库列名：deleted_at
  DateTimeColumn get deletedAt => dateTime().nullable().named('deleted_at')();

  /// 是否为模拟数据（v3.1：用于 Debug 模式生成/清理、同步/导出隔离）。
  BoolColumn get isMockData => boolean().withDefault(const Constant(false))();
}
