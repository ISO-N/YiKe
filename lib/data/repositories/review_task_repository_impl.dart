/// 文件用途：复习任务仓储实现（ReviewTaskRepositoryImpl）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/review_task.dart';
import '../../domain/entities/task_day_stats.dart';
import '../../domain/entities/task_timeline.dart';
import '../../domain/repositories/review_task_repository.dart';
import '../models/review_task_with_item_model.dart';
import '../database/daos/review_task_dao.dart';
import '../database/database.dart';
import '../sync/sync_log_writer.dart';

/// 复习任务仓储实现。
class ReviewTaskRepositoryImpl implements ReviewTaskRepository {
  /// 构造函数。
  ///
  /// 参数：
  /// - [dao] 复习任务 DAO。
  /// 异常：无。
  ReviewTaskRepositoryImpl({required this.dao, SyncLogWriter? syncLogWriter})
    : _sync = syncLogWriter;

  final ReviewTaskDao dao;
  final SyncLogWriter? _sync;

  @override
  Future<ReviewTaskEntity> create(ReviewTaskEntity task) async {
    final now = DateTime.now();
    final id = await dao.insertReviewTask(
      ReviewTasksCompanion.insert(
        learningItemId: task.learningItemId,
        reviewRound: task.reviewRound,
        scheduledDate: task.scheduledDate,
        status: Value(task.status.toDbValue()),
        completedAt: Value(task.completedAt),
        skippedAt: Value(task.skippedAt),
        createdAt: Value(task.createdAt),
        updatedAt: Value(now),
      ),
    );

    final sync = _sync;
    if (sync != null) {
      final ts = now.millisecondsSinceEpoch;
      final origin = await sync.resolveOriginKey(
        entityType: 'review_task',
        localEntityId: id,
        appliedAtMs: ts,
      );
      final learningOrigin = await sync.resolveOriginKey(
        entityType: 'learning_item',
        localEntityId: task.learningItemId,
        appliedAtMs: ts,
      );
      await sync.logEvent(
        origin: origin,
        entityType: 'review_task',
        operation: 'create',
        data: {
          'learning_origin_device_id': learningOrigin.deviceId,
          'learning_origin_entity_id': learningOrigin.entityId,
          'review_round': task.reviewRound,
          'scheduled_date': task.scheduledDate.toIso8601String(),
          'status': task.status.toDbValue(),
          'completed_at': task.completedAt?.toIso8601String(),
          'skipped_at': task.skippedAt?.toIso8601String(),
          'created_at': task.createdAt.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        timestampMs: ts,
      );
    }

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
  Future<List<ReviewTaskViewEntity>> getTodayCompletedTasks() async {
    final rows = await dao.getTodayCompletedTasksWithItem();
    return rows.map(_toViewEntity).toList();
  }

  @override
  Future<List<ReviewTaskViewEntity>> getTodaySkippedTasks() async {
    final rows = await dao.getTodaySkippedTasksWithItem();
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
    await _logTaskUpdateById(id);
  }

  @override
  Future<void> skipTask(int id) async {
    await dao.updateTaskStatus(id, 'skipped', skippedAt: DateTime.now());
    await _logTaskUpdateById(id);
  }

  @override
  Future<void> completeTasks(List<int> ids) async {
    await dao.updateTaskStatusBatch(ids, 'done', timestamp: DateTime.now());
    for (final id in ids) {
      await _logTaskUpdateById(id);
    }
  }

  @override
  Future<void> skipTasks(List<int> ids) async {
    await dao.updateTaskStatusBatch(ids, 'skipped', timestamp: DateTime.now());
    for (final id in ids) {
      await _logTaskUpdateById(id);
    }
  }

  @override
  Future<void> undoTaskStatus(int id) async {
    await dao.undoTaskStatus(id);
    await _logTaskUpdateById(id);
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
            isMockData: row.isMockData,
          ),
        )
        .toList();
  }

  @override
  Future<(int all, int pending, int done, int skipped)>
  getGlobalTaskStatusCounts() {
    return dao.getGlobalTaskStatusCounts();
  }

  @override
  Future<TaskTimelinePageEntity> getTaskTimelinePage({
    ReviewTaskStatus? status,
    TaskTimelineCursorEntity? cursor,
    int limit = 20,
  }) async {
    // 取 limit+1 判断是否还有下一页，避免 UI 误判“已到底”。
    final fetchSize = limit + 1;
    final rows = await dao.getTaskTimelinePageWithItem(
      status: status?.toDbValue(),
      cursorOccurredAt: cursor?.occurredAt,
      cursorTaskId: cursor?.taskId,
      limit: fetchSize,
    );

    final hasMore = rows.length > limit;
    final pageRows = hasMore ? rows.take(limit).toList() : rows;

    final items = pageRows
        .map(
          (r) => ReviewTaskTimelineItemEntity(
            task: _toViewEntity(r.model),
            occurredAt: r.occurredAt,
          ),
        )
        .toList();

    TaskTimelineCursorEntity? nextCursor;
    if (hasMore && items.isNotEmpty) {
      final last = items.last;
      nextCursor = TaskTimelineCursorEntity(
        occurredAt: last.occurredAt,
        taskId: last.task.taskId,
      );
    }

    return TaskTimelinePageEntity(items: items, nextCursor: nextCursor);
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

  Future<void> _logTaskUpdateById(int id) async {
    final sync = _sync;
    if (sync == null) return;

    final row = await dao.getReviewTaskById(id);
    if (row == null) return;

    // v3.1：Mock 数据不参与同步，因此不写入 update 日志。
    if (row.isMockData) return;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final origin = await sync.resolveOriginKey(
      entityType: 'review_task',
      localEntityId: row.id,
      appliedAtMs: ts,
    );
    final learningOrigin = await sync.resolveOriginKey(
      entityType: 'learning_item',
      localEntityId: row.learningItemId,
      appliedAtMs: ts,
    );

    await sync.logEvent(
      origin: origin,
      entityType: 'review_task',
      operation: 'update',
      data: {
        'learning_origin_device_id': learningOrigin.deviceId,
        'learning_origin_entity_id': learningOrigin.entityId,
        'review_round': row.reviewRound,
        'scheduled_date': row.scheduledDate.toIso8601String(),
        'status': row.status,
        'completed_at': row.completedAt?.toIso8601String(),
        'skipped_at': row.skippedAt?.toIso8601String(),
        'created_at': row.createdAt.toIso8601String(),
        'updated_at': (row.updatedAt ?? row.createdAt).toIso8601String(),
      },
      timestampMs: ts,
    );
  }
}
