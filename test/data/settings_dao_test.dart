// 文件用途：SettingsDao 单元测试（key-value 读写与批量 upsert）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/data/database/daos/settings_dao.dart';
import 'package:yike/data/database/database.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = createInMemoryDatabase();
    dao = SettingsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertValue / getValue 可正常读写', () async {
    await dao.upsertValue('k1', 'v1');
    expect(await dao.getValue('k1'), 'v1');
  });

  test('upsertValues 支持批量写入', () async {
    await dao.upsertValues({'k1': 'v1', 'k2': 'v2'});
    expect(await dao.getValue('k1'), 'v1');
    expect(await dao.getValue('k2'), 'v2');
  });
}

