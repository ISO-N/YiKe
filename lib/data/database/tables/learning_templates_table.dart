/// 文件用途：Drift 表定义 - 学习模板表（learning_templates），用于快速模板（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

/// 学习模板表。
///
/// 说明：
/// - 存储用户保存的常用录入模板
/// - titlePattern/notePattern 支持占位符（如 {date}）
class LearningTemplates extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 模板名称（用户可读，≤30）。
  TextColumn get name => text().withLength(min: 1, max: 30)();

  /// 标题模板（必填，≤50）。
  TextColumn get titlePattern => text().withLength(min: 1, max: 50)();

  /// 备注模板（可选）。
  TextColumn get notePattern => text().nullable()();

  /// 默认标签（JSON 字符串，如 ["英语","单词"]）。
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// 排序字段（越小越靠前）。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间（可空）。
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
