// 文件用途：数据库迁移回归测试——修复“schemaVersion 已升级但同步表缺失”导致配对/同步失败的问题。
// 作者：Codex
// 创建日期：2026-02-28

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/database.dart';

void main() {
  test('当 user_version=4 且缺失同步表时，升级到 v5 会补齐 sync_* 表', () async {
    final tmp = await Directory.systemTemp.createTemp('yike_db_migrate_');
    final dbFile = File('${tmp.path}${Platform.pathSeparator}yike_migrate.db');

    // 1) 先按当前版本创建完整数据库，再人为删除同步表并回写 user_version=4，
    //    模拟历史环境中“版本号已提升但表未创建/被误删”的异常状态。
    final db1 = AppDatabase(NativeDatabase(dbFile));
    try {
      await db1.customSelect('SELECT 1 as v').getSingle();

      await db1.customStatement('DROP TABLE IF EXISTS sync_devices');
      await db1.customStatement('DROP TABLE IF EXISTS sync_logs');
      await db1.customStatement('DROP TABLE IF EXISTS sync_entity_mappings');

      // 关键：把 user_version 回退到 4，让下一次打开触发 onUpgrade(4 -> 5)。
      await db1.customStatement('PRAGMA user_version = 4');
    } finally {
      await db1.close();
    }

    // 2) 再次打开：应触发补偿性迁移，自动补齐缺失的 sync_* 表。
    final db2 = AppDatabase(NativeDatabase(dbFile));
    try {
      await db2.customSelect('SELECT 1 as v').getSingle();

      final rows = await db2
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('sync_devices','sync_logs','sync_entity_mappings')",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();

      expect(names.contains('sync_devices'), true);
      expect(names.contains('sync_logs'), true);
      expect(names.contains('sync_entity_mappings'), true);
    } finally {
      await db2.close();
    }
  });
}
