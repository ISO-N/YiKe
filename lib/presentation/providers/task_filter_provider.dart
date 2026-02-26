/// 文件用途：复习任务状态筛选 Provider（v3.1 F14.2），用于日历当日任务列表筛选。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/review_task.dart';
import 'calendar_provider.dart';

/// 复习任务筛选条件。
enum ReviewTaskFilter {
  /// 全部。
  all,

  /// 待复习。
  pending,

  /// 已完成。
  done,

  /// 已跳过。
  skipped,
}

/// 当前筛选条件 Provider（全局保持，切换月份/重新打开 BottomSheet 不丢失）。
final reviewTaskFilterProvider = StateProvider<ReviewTaskFilter>(
  (ref) => ReviewTaskFilter.all,
);

/// 当日任务各状态数量统计 Provider。
final selectedDayTaskCountsProvider = Provider<TaskStatusCounts>((ref) {
  final tasks = ref.watch(calendarProvider).selectedDayTasks;
  var pending = 0;
  var done = 0;
  var skipped = 0;
  for (final t in tasks) {
    switch (t.status) {
      case ReviewTaskStatus.pending:
        pending++;
        break;
      case ReviewTaskStatus.done:
        done++;
        break;
      case ReviewTaskStatus.skipped:
        skipped++;
        break;
    }
  }
  return TaskStatusCounts(
    all: tasks.length,
    pending: pending,
    done: done,
    skipped: skipped,
  );
});

/// 过滤后的当日任务列表 Provider。
final filteredSelectedDayTasksProvider = Provider<List<ReviewTaskViewEntity>>((ref) {
  final tasks = ref.watch(calendarProvider).selectedDayTasks;
  final filter = ref.watch(reviewTaskFilterProvider);

  return switch (filter) {
    ReviewTaskFilter.all => tasks,
    ReviewTaskFilter.pending =>
      tasks.where((t) => t.status == ReviewTaskStatus.pending).toList(),
    ReviewTaskFilter.done =>
      tasks.where((t) => t.status == ReviewTaskStatus.done).toList(),
    ReviewTaskFilter.skipped =>
      tasks.where((t) => t.status == ReviewTaskStatus.skipped).toList(),
  };
});

/// 任务状态计数（用于 UI 展示）。
class TaskStatusCounts {
  const TaskStatusCounts({
    required this.all,
    required this.pending,
    required this.done,
    required this.skipped,
  });

  final int all;
  final int pending;
  final int done;
  final int skipped;
}
