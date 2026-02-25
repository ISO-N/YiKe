// 文件用途：AppDatabase.open 单元测试（通过 PathProviderPlatform Fake 覆盖 open() 分支）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:yike/data/database/database.dart';

/// PathProviderPlatform 假实现：仅提供 documentsPath。
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  test('open 会使用 path_provider 目录创建数据库文件并可执行查询', () async {
    final tmp = await Directory.systemTemp.createTemp('yike_db_test_');
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(tmp.path);

    try {
      final db = await AppDatabase.open();
      // 触发实际打开/建表流程。
      await db.customSelect('SELECT 1 as v').getSingle();
      await db.close();

      expect(
        File('${tmp.path}${Platform.pathSeparator}yike.db').existsSync(),
        true,
      );
    } finally {
      PathProviderPlatform.instance = original;
    }
  });
}
