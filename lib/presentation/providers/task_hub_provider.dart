/// 文件用途：任务中心状态管理（任务时间线 + 游标分页 + 状态筛选）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/review_task.dart';
import '../../domain/entities/task_timeline.dart';
import 'calendar_provider.dart';
import 'home_tasks_provider.dart';
import 'statistics_provider.dart';
import 'task_filter_provider.dart';

/// 任务中心页面状态。
class TaskHubState {
  /// 构造函数。
  const TaskHubState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.filter,
    required this.counts,
    required this.items,
    required this.nextCursor,
    required this.expandedTaskIds,
    this.errorMessage,
  });

  /// 首次/刷新加载中。
  final bool isLoading;

  /// 追加分页加载中。
  final bool isLoadingMore;

  /// 当前筛选（单选）。
  final ReviewTaskFilter filter;

  /// 全量任务状态计数（用于筛选栏展示）。
  final TaskStatusCounts counts;

  /// 已加载的时间线条目（按发生时间倒序）。
  final List<ReviewTaskTimelineItemEntity> items;

  /// 下一页游标；为空表示没有更多数据。
  final TaskTimelineCursorEntity? nextCursor;

  /// 当前展开的任务集合（点击卡片展开操作区）。
  final Set<int> expandedTaskIds;

  /// 错误信息（用于 UI 展示）。
  final String? errorMessage;

  factory TaskHubState.initial() => const TaskHubState(
    isLoading: true,
    isLoadingMore: false,
    filter: ReviewTaskFilter.all,
    counts: TaskStatusCounts(all: 0, pending: 0, done: 0, skipped: 0),
    items: [],
    nextCursor: null,
    expandedTaskIds: {},
    errorMessage: null,
  );

  TaskHubState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    ReviewTaskFilter? filter,
    TaskStatusCounts? counts,
    List<ReviewTaskTimelineItemEntity>? items,
    TaskTimelineCursorEntity? nextCursor,
    bool clearCursor = false,
    Set<int>? expandedTaskIds,
    String? errorMessage,
  }) {
    return TaskHubState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter ?? this.filter,
      counts: counts ?? this.counts,
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      expandedTaskIds: expandedTaskIds ?? this.expandedTaskIds,
      errorMessage: errorMessage,
    );
  }
}

/// 任务中心 Notifier。
class TaskHubNotifier extends StateNotifier<TaskHubState> {
  /// 构造函数。
  TaskHubNotifier(this._ref) : super(TaskHubState.initial()) {
    loadInitial();
  }

  final Ref _ref;

  /// 首次加载：同时拉取计数与首屏时间线。
  Future<void> loadInitial() async {
    await Future.wait([_loadCounts(), refresh()]);
  }

  /// 切换筛选并刷新列表。
  Future<void> setFilter(ReviewTaskFilter next) async {
    if (next == state.filter) return;
    state = state.copyWith(filter: next, expandedTaskIds: <int>{});
    await refresh();
  }

  /// 下拉刷新：重置游标并重新加载首屏。
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      items: const [],
      clearCursor: true,
      errorMessage: null,
      expandedTaskIds: <int>{},
    );
    try {
      final useCase = _ref.read(getTasksByTimeUseCaseProvider);
      final status = _mapFilterToStatus(state.filter);
      final page = await useCase.execute(status: status, cursor: null, limit: 20);
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        nextCursor: page.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 追加分页：根据游标加载下一页。
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.isLoading || state.isLoadingMore || cursor == null) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    try {
      final useCase = _ref.read(getTasksByTimeUseCaseProvider);
      final status = _mapFilterToStatus(state.filter);
      final page =
          await useCase.execute(status: status, cursor: cursor, limit: 20);

      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  /// 展开/收起任务卡片。
  void toggleExpanded(int taskId) {
    final next = Set<int>.from(state.expandedTaskIds);
    if (next.contains(taskId)) {
      next.remove(taskId);
    } else {
      next.add(taskId);
    }
    state = state.copyWith(expandedTaskIds: next);
  }

  /// 完成任务并刷新列表与相关页面数据。
  Future<void> completeTask(int taskId) async {
    await _ref.read(completeReviewTaskUseCaseProvider).execute(taskId);
    _invalidateRelatedPages();
    await Future.wait([_loadCounts(), refresh()]);
  }

  /// 跳过任务并刷新列表与相关页面数据。
  Future<void> skipTask(int taskId) async {
    await _ref.read(skipReviewTaskUseCaseProvider).execute(taskId);
    _invalidateRelatedPages();
    await Future.wait([_loadCounts(), refresh()]);
  }

  /// 撤销任务状态并刷新列表与相关页面数据。
  Future<void> undoTaskStatus(int taskId) async {
    await _ref.read(undoTaskStatusUseCaseProvider).execute(taskId);
    _invalidateRelatedPages();
    await Future.wait([_loadCounts(), refresh()]);
  }

  Future<void> _loadCounts() async {
    try {
      final useCase = _ref.read(getTasksByTimeUseCaseProvider);
      final (all, pending, done, skipped) = await useCase.getStatusCounts();
      state = state.copyWith(
        counts: TaskStatusCounts(
          all: all,
          pending: pending,
          done: done,
          skipped: skipped,
        ),
      );
    } catch (_) {
      // 计数失败不阻断主流程：列表仍可展示。
    }
  }

  ReviewTaskStatus? _mapFilterToStatus(ReviewTaskFilter filter) {
    return switch (filter) {
      ReviewTaskFilter.all => null,
      ReviewTaskFilter.pending => ReviewTaskStatus.pending,
      ReviewTaskFilter.done => ReviewTaskStatus.done,
      ReviewTaskFilter.skipped => ReviewTaskStatus.skipped,
    };
  }

  void _invalidateRelatedPages() {
    // 完成/跳过/撤销会影响首页、日历与统计口径，因此需要主动刷新相关页面状态。
    _ref.invalidate(homeTasksProvider);
    _ref.invalidate(calendarProvider);
    _ref.invalidate(statisticsProvider);
  }
}

/// 任务中心 Provider。
final taskHubProvider = StateNotifierProvider<TaskHubNotifier, TaskHubState>((
  ref,
) {
  return TaskHubNotifier(ref);
});

