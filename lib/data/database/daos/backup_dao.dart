/// 文件用途：BackupDao - 备份/恢复数据库访问封装（导出所需的跨表查询）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/backup_file.dart';
import '../database.dart';

/// 备份 DAO。
///
/// 说明：
/// - 仅负责“导出读取”相关查询（跨表 join、字段映射）
/// - 导入写入逻辑由仓储实现统一组织（需要策略/事务/快照等）
class BackupDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例
  BackupDao(this.db);

  final AppDatabase db;

  /// 读取可导出的学习内容（默认排除 Mock 数据）。
  Future<List<BackupLearningItemEntity>> getLearningItemsForBackup() async {
    final rows = await (db.select(
      db.learningItems,
    )..where((t) => t.isMockData.equals(false))).get();

    return rows
        .map(
          (row) => BackupLearningItemEntity(
            uuid: row.uuid,
            title: row.title,
            description: row.description,
            note: row.note,
            tags: _parseStringList(row.tags),
            learningDate: row.learningDate.toIso8601String(),
            createdAt: row.createdAt.toIso8601String(),
            updatedAt: row.updatedAt?.toIso8601String(),
            isDeleted: row.isDeleted,
            deletedAt: row.deletedAt?.toIso8601String(),
          ),
        )
        .toList();
  }

  /// 读取可导出的学习子任务（默认排除 Mock 数据），并将外键转为 uuid（learningItemUuid）。
  Future<List<BackupLearningSubtaskEntity>> getLearningSubtasksForBackup() async {
    final query = db.select(db.learningSubtasks).join([
      innerJoin(
        db.learningItems,
        db.learningItems.id.equalsExp(db.learningSubtasks.learningItemId),
      ),
    ]);
    query.where(db.learningSubtasks.isMockData.equals(false));

    final rows = await query.get();
    return rows.map((row) {
      final subtask = row.readTable(db.learningSubtasks);
      final item = row.readTable(db.learningItems);
      return BackupLearningSubtaskEntity(
        uuid: subtask.uuid,
        learningItemUuid: item.uuid,
        content: subtask.content,
        sortOrder: subtask.sortOrder,
        createdAt: subtask.createdAt.toIso8601String(),
        updatedAt: subtask.updatedAt?.toIso8601String(),
      );
    }).toList();
  }

  /// 读取可导出的复习任务（默认排除 Mock 数据），并将外键转为 uuid（learningItemUuid）。
  Future<List<BackupReviewTaskEntity>> getReviewTasksForBackup() async {
    final query = db.select(db.reviewTasks).join([
      innerJoin(
        db.learningItems,
        db.learningItems.id.equalsExp(db.reviewTasks.learningItemId),
      ),
    ]);
    query.where(db.reviewTasks.isMockData.equals(false));

    final rows = await query.get();
    return rows.map((row) {
      final task = row.readTable(db.reviewTasks);
      final item = row.readTable(db.learningItems);
      return BackupReviewTaskEntity(
        uuid: task.uuid,
        learningItemUuid: item.uuid,
        reviewRound: task.reviewRound,
        scheduledDate: task.scheduledDate.toIso8601String(),
        status: task.status,
        completedAt: task.completedAt?.toIso8601String(),
        skippedAt: task.skippedAt?.toIso8601String(),
        createdAt: task.createdAt.toIso8601String(),
        updatedAt: task.updatedAt?.toIso8601String(),
      );
    }).toList();
  }

  /// 读取可导出的复习记录（默认排除 Mock 数据），并将外键转为 uuid（reviewTaskUuid）。
  Future<List<BackupReviewRecordEntity>> getReviewRecordsForBackup() async {
    final query = db.select(db.reviewRecords).join([
      innerJoin(
        db.reviewTasks,
        db.reviewTasks.id.equalsExp(db.reviewRecords.reviewTaskId),
      ),
    ]);
    query.where(db.reviewTasks.isMockData.equals(false));

    final rows = await query.get();
    return rows.map((row) {
      final record = row.readTable(db.reviewRecords);
      final task = row.readTable(db.reviewTasks);
      return BackupReviewRecordEntity(
        uuid: record.uuid,
        reviewTaskUuid: task.uuid,
        action: record.action,
        occurredAt: record.occurredAt.toIso8601String(),
        createdAt: record.createdAt.toIso8601String(),
      );
    }).toList();
  }

  List<String> _parseStringList(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }
}
