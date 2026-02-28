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
import 'tables/learning_templates_table.dart';
import 'tables/learning_topics_table.dart';
import 'tables/review_tasks_table.dart';
import 'tables/settings_table.dart';
import 'tables/sync_devices_table.dart';
import 'tables/sync_entity_mappings_table.dart';
import 'tables/sync_logs_table.dart';
import 'tables/topic_item_relations_table.dart';

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
    LearningTemplates,
    LearningTopics,
    TopicItemRelations,
    SyncDevices,
    SyncLogs,
    SyncEntityMappings,
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
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      // v1.4：为“调整计划/增加轮次”提供唯一定位键（learning_item_id + review_round）。
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_review_tasks_learning_item_round ON review_tasks (learning_item_id, review_round)',
      );
    },
    onUpgrade: (migrator, from, to) async {
      // v2.1：新增学习模板、学习主题与关联表。
      if (from < 2) {
        await migrator.createTable(learningTemplates);
        await migrator.createTable(learningTopics);
        await migrator.createTable(topicItemRelations);
      }

      // v3.0：新增局域网同步相关表 + 复习任务更新时间字段。
      if (from < 3) {
        await migrator.createTable(syncDevices);
        await migrator.createTable(syncLogs);
        await migrator.createTable(syncEntityMappings);

        await migrator.addColumn(reviewTasks, reviewTasks.updatedAt);

        // 兼容：为历史任务补齐 updatedAt，便于同步冲突解决（以 createdAt 兜底）。
        await customStatement(
          'UPDATE review_tasks SET updated_at = created_at WHERE updated_at IS NULL',
        );
      }

      // v3.1：新增 isMockData 字段（用于 Debug 模拟数据隔离）。
      if (from < 4) {
        await migrator.addColumn(learningItems, learningItems.isMockData);
        await migrator.addColumn(reviewTasks, reviewTasks.isMockData);
      }

      // v3.2：补偿性迁移——确保局域网同步相关表存在。
      //
      // 背景：历史版本中曾出现“schemaVersion 已提升，但同步表未创建”的情况，导致：
      // - 主机端能显示配对码（内存态），但配对确认写库失败 -> 客户端提示“同步失败”
      // - 两端“已连接设备”列表始终为空（表不存在或查询失败）
      //
      // 处理：在 v5 强制兜底创建缺失表（仅在确实缺失时创建，避免影响已有数据）。
      if (from < 5) {
        final rows = await customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('sync_devices','sync_logs','sync_entity_mappings')",
        ).get();
        final existing = rows.map((r) => r.read<String>('name')).toSet();

        if (!existing.contains('sync_devices')) {
          await migrator.createTable(syncDevices);
        }
        if (!existing.contains('sync_logs')) {
          await migrator.createTable(syncLogs);
        }
        if (!existing.contains('sync_entity_mappings')) {
          await migrator.createTable(syncEntityMappings);
        }
      }

      // v3.3：为任务历史/任务中心新增索引（提升 completedAt/skippedAt 查询性能）。
      if (from < 6) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_completed_at_status ON review_tasks (completed_at, status)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_skipped_at_status ON review_tasks (skipped_at, status)',
        );
      }

      // v1.4：任务操作增强
      // - learning_items：新增 is_deleted / deleted_at（软删除）
      // - review_tasks：移除 review_round 的 CHECK 约束，允许扩展至 10 轮（应用层控制上限）
      // - 新增唯一索引：review_tasks(learning_item_id, review_round)
      if (from < 7) {
        Future<bool> hasColumn(String table, String column) async {
          final rows = await customSelect('PRAGMA table_info($table)').get();
          return rows.any((r) => r.read<String>('name') == column);
        }

        // 兼容：若 user_version 异常回退（或历史脏库）导致列已存在，则跳过 addColumn，避免重复添加报错。
        if (!await hasColumn('learning_items', 'is_deleted')) {
          await migrator.addColumn(learningItems, learningItems.isDeleted);
        }
        if (!await hasColumn('learning_items', 'deleted_at')) {
          await migrator.addColumn(learningItems, learningItems.deletedAt);
        }

        // Drift 会通过重建表的方式应用约束差异（移除 CHECK 约束）。
        await migrator.alterTable(TableMigration(reviewTasks));

        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_review_tasks_learning_item_round ON review_tasks (learning_item_id, review_round)',
        );
      }
    },
    beforeOpen: (details) async {
      // 开启外键约束，确保级联删除生效。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
