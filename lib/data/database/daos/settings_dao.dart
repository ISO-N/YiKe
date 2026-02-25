/// 文件用途：SettingsDao - 应用设置数据库访问封装（key-value）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 设置 DAO。
///
/// 说明：提供 key-value 读写与 upsert。
class SettingsDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例。
  /// 异常：无。
  SettingsDao(this.db);

  final AppDatabase db;

  /// 根据 key 读取设置值。
  ///
  /// 返回值：value（字符串）或 null。
  /// 异常：数据库查询失败时可能抛出异常。
  Future<String?> getValue(String key) async {
    final row = await (db.select(db.appSettingsTable)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// 写入设置值（存在则更新，不存在则插入）。
  ///
  /// 参数：
  /// - [key] 键名
  /// - [value] 值（字符串，通常为 JSON 字符串）
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<void> upsertValue(String key, String value) async {
    final companion = AppSettingsTableCompanion.insert(
      key: key,
      value: value,
      updatedAt: Value(DateTime.now()),
    );

    await db.into(db.appSettingsTable).insertOnConflictUpdate(companion);
  }

  /// 批量写入设置值。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<void> upsertValues(Map<String, String> values) async {
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.appSettingsTable,
        values.entries
            .map(
              (e) => AppSettingsTableCompanion.insert(
                key: e.key,
                value: e.value,
                updatedAt: Value(DateTime.now()),
              ),
            )
            .toList(),
      );
    });
  }
}

