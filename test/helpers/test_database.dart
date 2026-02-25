// 文件用途：测试辅助 - 创建内存数据库（Drift NativeDatabase.memory），用于 DAO/Repository 单测。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:drift/native.dart';
import 'package:yike/data/database/database.dart';

/// 创建一个用于测试的内存数据库实例。
///
/// 说明：
/// - 使用内存数据库避免依赖真实文件系统与路径插件。
/// - 调用方需在测试结束后执行 `db.close()` 释放资源。
AppDatabase createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
