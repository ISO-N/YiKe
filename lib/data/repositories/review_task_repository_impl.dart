/// 文件用途：复习任务仓储实现（ReviewTaskRepositoryImpl）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/review_task.dart';
import '../../domain/entities/task_day_stats.dart';
import '../../domain/repositories/review_task_repository.dart';
import '../models/review_task_with_item_model.dart';
import '../database/daos/review_task_dao.dart';
import '../database/database.dart';

/// 复习任务仓储实现。
class ReviewTaskRepositoryImpl implements ReviewTaskRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 复习任务 DAO。
  /// 异常：无。
  ReviewTaskRepositoryImpl({required this.dao});

  final ReviewTaskDao dao;

  @override
  Future<ReviewTaskEntity> create(ReviewTaskEntity task) async {
    final id = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: task.learningItemId,
        reviewRound: task.reviewRound,
        scheduledDate: task.scheduledDate,
        status: Value(task.status.toDbValue()),
        completedAt: Value(task.completedAt),
        skippedAt: Value(task.skippedAt),
        createdAt: Value(task.createdAt),
      ),
    );
    return task.copyWith(id: id);
  }

  @override
  Future<List<ReviewTaskEntity>> createBatch(
    List<ReviewTaskEntity> tasks,
  ) async {
    // v1.0 MVP：每次最多插入 5 条任务，逐条插入以获得 ID，便于后续扩展（如按任务调度通知）。
    final saved = <ReviewTaskEntity>[];
    for (final task in tasks) {
      saved.add(await create(task));
    }
    return saved;
  }

  @override
  Future<List<ReviewTaskViewEntity>> getOverduePendingTasks() async {
    final rows = await dao.getOverdueTasksWithItem();
    return rows.map(_toViewEntity).toList();
  }

  @override
  Future<List<ReviewTaskViewEntity>> getTodayPendingTasks() async {
    final rows = await dao.getTodayPendingTasksWithItem();
    return rows.map(_toViewEntity).toList();
  }

  @override
  Future<List<ReviewTaskViewEntity>> getTasksByDate(DateTime date) async {
    final rows = await dao.getTasksByDateWithItem(date);
    return rows.map(_toViewEntity).toList();
  }

  @override
  Future<void> completeTask(int id) async {
    await dao.updateTaskStatus(id, 'done', completedAt: DateTime.now());
  }

  @override
  Future<void> skipTask(int id) async {
    await dao.updateTaskStatus(id, 'skipped', skippedAt: DateTime.now());
  }

  @override
  Future<void> completeTasks(List<int> ids) async {
    await dao.updateTaskStatusBatch(ids, 'done', timestamp: DateTime.now());
  }

  @override
  Future<void> skipTasks(List<int> ids) async {
    await dao.updateTaskStatusBatch(ids, 'skipped', timestamp: DateTime.now());
  }

  @override
  Future<(int completed, int total)> getTaskStats(DateTime date) {
    return dao.getTaskStats(date);
  }

  @override
  Future<Map<DateTime, TaskDayStats>> getMonthlyTaskStats(int year, int month) {
    return dao.getMonthlyTaskStats(year, month);
  }

  @override
  Future<List<ReviewTaskViewEntity>> getTasksInRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await dao.getTasksInRange(start, end);
    return rows.map(_toViewEntity).toList();
  }

  @override
  Future<int> getConsecutiveCompletedDays({DateTime? today}) {
    return dao.getConsecutiveCompletedDays(today: today);
  }

  @override
  Future<(int completed, int total)> getTaskStatsInRange(
    DateTime start,
    DateTime end,
  ) {
    return dao.getTaskStatsInRange(start, end);
  }

  @override
  Future<List<ReviewTaskEntity>> getAllTasks() async {
    final rows = await dao.getAllTasks();
    return rows
        .map(
          (row) => ReviewTaskEntity(
            id: row.id,
            learningItemId: row.learningItemId,
            reviewRound: row.reviewRound,
            scheduledDate: row.scheduledDate,
            status: ReviewTaskStatusX.fromDbValue(row.status),
            completedAt: row.completedAt,
            skippedAt: row.skippedAt,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  ReviewTaskViewEntity _toViewEntity(ReviewTaskWithItemModel model) {
    final task = model.task;
    final item = model.item;

    return ReviewTaskViewEntity(
      taskId: task.id,
      learningItemId: item.id,
      title: item.title,
      note: item.note,
      tags: _parseTags(item.tags),
      reviewRound: task.reviewRound,
      scheduledDate: task.scheduledDate,
      status: ReviewTaskStatusX.fromDbValue(task.status),
      completedAt: task.completedAt,
      skippedAt: task.skippedAt,
    );
  }

  List<String> _parseTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
