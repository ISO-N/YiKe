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
    // 关键逻辑：以 `key` 作为冲突目标进行 upsert。
    //
    // 背景：`app_settings_table` 的主键为自增 `id`，同时对 `key` 建了唯一约束。
    // Drift 的 `insertOnConflictUpdate` 默认按主键（id）做 ON CONFLICT，无法覆盖 UNIQUE(key) 的冲突，
    // 会导致二次写入同一 key 时抛出：UNIQUE constraint failed: app_settings_table.key（SQLite 2067）。
    final now = DateTime.now();
    final companion = AppSettingsTableCompanion.insert(
      key: key,
      value: value,
      updatedAt: Value(now),
    );

    await db.into(db.appSettingsTable).insert(
          companion,
          onConflict: DoUpdate(
            (old) => AppSettingsTableCompanion(
              // 仅更新 value 与更新时间，避免误改 key。
              value: Value(value),
              updatedAt: Value(now),
            ),
            target: [db.appSettingsTable.key],
          ),
        );
  }

  /// 批量写入设置值。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：数据库写入失败时可能抛出异常。
  Future<void> upsertValues(Map<String, String> values) async {
    // 关键逻辑：批量 upsert 同样需要以 `key` 作为冲突目标。
    // 设置项数量很少（个位数），这里使用 transaction + 循环插入，保证语义清晰且便于覆盖 UNIQUE(key) 冲突。
    await db.transaction(() async {
      for (final entry in values.entries) {
        await upsertValue(entry.key, entry.value);
      }
    });
  }
}

