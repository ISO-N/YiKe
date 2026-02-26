/// 文件用途：Drift 表定义 - 复习任务表（review_tasks）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:drift/drift.dart';

import 'learning_items_table.dart';

/// 复习任务表。
///
/// 说明：每条学习内容会生成 5 次复习任务（v1.0 固定间隔）。
@TableIndex(name: 'idx_scheduled_date', columns: {#scheduledDate})
@TableIndex(name: 'idx_status', columns: {#status})
@TableIndex(name: 'idx_learning_item_id', columns: {#learningItemId})
class ReviewTasks extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 外键：关联的学习内容 ID（删除学习内容时级联删除）。
  IntColumn get learningItemId =>
      integer().references(LearningItems, #id, onDelete: KeyAction.cascade)();

  /// 复习轮次（1-5）。
  IntColumn get reviewRound => integer()();

  /// 计划复习日期。
  DateTimeColumn get scheduledDate => dateTime()();

  /// 任务状态：pending(待复习)/done(已完成)/skipped(已跳过)。
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// 完成时间（完成后记录）。
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// 跳过时间（跳过后记录）。
  DateTimeColumn get skippedAt => dateTime().nullable()();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间（用于同步冲突解决，v3.0 新增）。
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// 是否为模拟数据（v3.1：用于 Debug 模式生成/清理、同步/导出隔离）。
  BoolColumn get isMockData => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => const [
    // 复习轮次范围约束（避免 Analyzer 对 self-reference 的提示）。
    'CHECK (review_round BETWEEN 1 AND 5)',
  ];
}
