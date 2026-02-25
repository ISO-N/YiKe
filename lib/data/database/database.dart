/// 文件用途：Drift 数据库定义与初始化（SQLite）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/learning_items_table.dart';
import 'tables/review_tasks_table.dart';
import 'tables/settings_table.dart';

part 'database.g.dart';

/// 应用数据库。
///
/// 说明：
/// - 数据库文件：`yike.db`
/// - v1.0 MVP：本地离线可用，任务数据不加密；设置项可在上层做加密存储。
@DriftDatabase(
  tables: [
    LearningItems,
    ReviewTasks,
    AppSettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 创建数据库实例。
  ///
  /// 参数：
  /// - [executor] Drift QueryExecutor。
  /// 返回值：AppDatabase。
  /// 异常：无（打开失败会在首次操作时抛出）。
  AppDatabase(super.executor);

  /// 打开默认数据库（文件落在应用文档目录）。
  ///
  /// 返回值：AppDatabase。
  /// 异常：路径获取失败/文件打开失败时可能抛出异常。
  static Future<AppDatabase> open() async {
    final executor = LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'yike.db'));
      return NativeDatabase(file);
    });
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          // v1.0 MVP：预留升级入口。
        },
        beforeOpen: (details) async {
          // 开启外键约束，确保级联删除生效。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
