/// 文件用途：Drift 表定义 - 复习记录表（review_records），用于备份恢复与行为追踪。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'review_tasks_table.dart';

/// 复习记录表。
///
/// 说明：
/// - 记录用户对复习任务的“行为事件”（完成/跳过/撤销等）
/// - 记录不可变：同一条记录一旦写入不应被修改（用于审计与备份合并）
/// - 与 review_tasks 为 1:N 关系（一个任务可能发生多次行为，如撤销后再次完成）
class ReviewRecords extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 业务唯一标识（UUID v4）。
  ///
  /// 说明：用于备份/恢复合并去重（records 以 uuid 作为不可变事件标识）。
  TextColumn get uuid =>
      text().withLength(min: 1, max: 36).clientDefault(() => const Uuid().v4())();

  /// 外键：关联复习任务 ID（删除任务时级联删除记录）。
  IntColumn get reviewTaskId =>
      integer().references(ReviewTasks, #id, onDelete: KeyAction.cascade)();

  /// 行为类型。
  ///
  /// 取值建议：
  /// - 'done'：完成
  /// - 'skipped'：跳过
  /// - 'undo'：撤销（done/skipped → pending）
  TextColumn get action => text().withLength(min: 1, max: 20)();

  /// 行为发生时间（用于时间线/统计口径）。
  DateTimeColumn get occurredAt => dateTime()();

  /// 创建时间（写入数据库时间）。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
