/// 文件用途：Drift 表定义 - 应用设置表（app_settings）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:drift/drift.dart';

/// 应用设置表。
///
/// 说明：使用 key-value 存储设置项；value 为 JSON 字符串。
class AppSettingsTable extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 设置键名（唯一）。
  TextColumn get key => text().unique()();

  /// 设置值（JSON 字符串）。
  TextColumn get value => text()();

  /// 更新时间。
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
