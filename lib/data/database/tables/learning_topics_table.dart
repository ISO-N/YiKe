/// 文件用途：Drift 表定义 - 学习主题表（learning_topics），用于内容关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

/// 学习主题表。
///
/// 说明：将多个相关学习内容关联成主题，便于按主题聚合查看进度。
class LearningTopics extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 主题名称（必填，≤50）。
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// 主题描述（可选）。
  TextColumn get description => text().nullable()();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新时间（可空）。
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
