/// 文件用途：首页任务状态管理（Riverpod StateNotifier）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/review_task.dart';
import '../../infrastructure/widget/widget_service.dart';
import 'calendar_provider.dart';
import 'statistics_provider.dart';

/// 首页任务状态。
class HomeTasksState {
  /// 构造函数。
  const HomeTasksState({
    required this.isLoading,
    required this.todayPending,
    required this.todayCompleted,
    required this.todaySkipped,
    required this.overduePending,
    required this.completedCount,
    required this.totalCount,
    required this.isSelectionMode,
    required this.selectedTaskIds,
    required this.expandedTaskIds,
    required this.topicFilterId,
    this.errorMessage,
  });

  final bool isLoading;
  final List<ReviewTaskViewEntity> todayPending;
  final List<ReviewTaskViewEntity> todayCompleted;
  final List<ReviewTaskViewEntity> todaySkipped;
  final List<ReviewTaskViewEntity> overduePending;
  final int completedCount;
  final int totalCount;
  final bool isSelectionMode;
  final Set<int> selectedTaskIds;

  /// 首页任务卡片展开状态（用于查看备注/标签详情与撤销按钮）。
  final Set<int> expandedTaskIds;

  /// 主题筛选（可选，F1.6）。
  ///
  /// 说明：当不为空时，仅展示属于该主题的任务。
  final int? topicFilterId;
  final String? errorMessage;

  factory HomeTasksState.initial() => const HomeTasksState(
    isLoading: true,
    todayPending: [],
    todayCompleted: [],
    todaySkipped: [],
    overduePending: [],
    completedCount: 0,
    totalCount: 0,
    isSelectionMode: false,
    selectedTaskIds: {},
    expandedTaskIds: {},
    topicFilterId: null,
  );

  HomeTasksState copyWith({
    bool? isLoading,
    List<ReviewTaskViewEntity>? todayPending,
    List<ReviewTaskViewEntity>? todayCompleted,
    List<ReviewTaskViewEntity>? todaySkipped,
    List<ReviewTaskViewEntity>? overduePending,
    int? completedCount,
    int? totalCount,
    bool? isSelectionMode,
    Set<int>? selectedTaskIds,
    Set<int>? expandedTaskIds,
    int? topicFilterId,
    String? errorMessage,
  }) {
    return HomeTasksState(
      isLoading: isLoading ?? this.isLoading,
      todayPending: todayPending ?? this.todayPending,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      todaySkipped: todaySkipped ?? this.todaySkipped,
      overduePending: overduePending ?? this.overduePending,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      expandedTaskIds: expandedTaskIds ?? this.expandedTaskIds,
      topicFilterId: topicFilterId ?? this.topicFilterId,
      errorMessage: errorMessage,
    );
  }
}

/// 首页任务 Notifier。
class HomeTasksNotifier extends StateNotifier<HomeTasksState> {
  /// 构造函数。
  HomeTasksNotifier(this._ref) : super(HomeTasksState.initial());

  final Ref _ref;

  /// 加载首页数据。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：异常会捕获并写入 [HomeTasksState.errorMessage]。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final useCase = _ref.read(getHomeTasksUseCaseProvider);
      final completedUseCase = _ref.read(getTodayCompletedTasksUseCaseProvider);
      final skippedUseCase = _ref.read(getTodaySkippedTasksUseCaseProvider);

      final resultFuture = useCase.execute();
      final completedFuture = completedUseCase.execute();
      final skippedFuture = skippedUseCase.execute();

      final result = await resultFuture;
      final todayCompleted = await completedFuture;
      final todaySkipped = await skippedFuture;

      final topicId = state.topicFilterId;
      if (topicId == null) {
        state = state.copyWith(
          isLoading: false,
          todayPending: result.todayPending,
          todayCompleted: todayCompleted,
          todaySkipped: todaySkipped,
          overduePending: result.overduePending,
          completedCount: result.completedCount,
          totalCount: result.totalCount,
        );
      } else {
        // v2.1：按主题筛选任务。
        final topicRepo = _ref.read(learningTopicRepositoryProvider);
        final itemIds = (await topicRepo.getItemIdsByTopicId(topicId)).toSet();

        final today = result.todayPending
            .where((t) => itemIds.contains(t.learningItemId))
            .toList();
        final overdue = result.overduePending
            .where((t) => itemIds.contains(t.learningItemId))
            .toList();
        final completedTasks = todayCompleted
            .where((t) => itemIds.contains(t.learningItemId))
            .toList();
        final skippedTasks =
            todaySkipped.where((t) => itemIds.contains(t.learningItemId)).toList();

        // 进度统计：重新按主题口径统计今日完成率（done/(done+pending)）。
        final repo = _ref.read(reviewTaskRepositoryProvider);
        final all = await repo.getTasksByDate(DateTime.now());
        final filtered = all.where((t) => itemIds.contains(t.learningItemId));
        final completedCount = filtered
            .where((t) => t.status == ReviewTaskStatus.done)
            .length;
        final totalCount = filtered
            .where((t) => t.status != ReviewTaskStatus.skipped)
            .length;

        state = state.copyWith(
          isLoading: false,
          todayPending: today,
          todayCompleted: completedTasks,
          todaySkipped: skippedTasks,
          overduePending: overdue,
          completedCount: completedCount,
          totalCount: totalCount,
        );
      }

      // 同步桌面小组件数据（v1.0 Android 展示）。
      await _syncWidget();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 展开/收起任务卡片详情区域。
  void toggleExpanded(int taskId) {
    final next = Set<int>.from(state.expandedTaskIds);
    if (next.contains(taskId)) {
      next.remove(taskId);
    } else {
      next.add(taskId);
    }
    state = state.copyWith(expandedTaskIds: next);
  }

  /// 开关选择模式（用于批量完成/跳过）。
  void toggleSelectionMode() {
    if (state.isSelectionMode) {
      state = state.copyWith(isSelectionMode: false, selectedTaskIds: <int>{});
    } else {
      state = state.copyWith(isSelectionMode: true, selectedTaskIds: <int>{});
    }
  }

  /// 设置主题筛选（null 表示全部）。
  Future<void> setTopicFilter(int? topicId) async {
    state = state.copyWith(topicFilterId: topicId);
    await load();
  }

  /// 切换某任务的选中状态。
  void toggleSelected(int taskId) {
    final next = Set<int>.from(state.selectedTaskIds);
    if (next.contains(taskId)) {
      next.remove(taskId);
    } else {
      next.add(taskId);
    }
    state = state.copyWith(selectedTaskIds: next);
  }

  /// 完成单个任务。
  Future<void> completeTask(int taskId) async {
    final useCase = _ref.read(completeReviewTaskUseCaseProvider);
    await useCase.execute(taskId);
    _invalidateRelatedPages();
    await load();
  }

  /// 跳过单个任务。
  Future<void> skipTask(int taskId) async {
    final useCase = _ref.read(skipReviewTaskUseCaseProvider);
    await useCase.execute(taskId);
    _invalidateRelatedPages();
    await load();
  }

  /// 批量完成所选任务。
  Future<void> completeSelected() async {
    final ids = state.selectedTaskIds.toList();
    if (ids.isEmpty) return;
    final useCase = _ref.read(completeReviewTaskUseCaseProvider);
    await useCase.executeBatch(ids);
    state = state.copyWith(isSelectionMode: false, selectedTaskIds: <int>{});
    _invalidateRelatedPages();
    await load();
  }

  /// 批量跳过所选任务。
  Future<void> skipSelected() async {
    final ids = state.selectedTaskIds.toList();
    if (ids.isEmpty) return;
    final useCase = _ref.read(skipReviewTaskUseCaseProvider);
    await useCase.executeBatch(ids);
    state = state.copyWith(isSelectionMode: false, selectedTaskIds: <int>{});
    _invalidateRelatedPages();
    await load();
  }

  /// 撤销任务状态（done/skipped → pending）。
  Future<void> undoTaskStatus(int taskId) async {
    final useCase = _ref.read(undoTaskStatusUseCaseProvider);
    await useCase.execute(taskId);
    _invalidateRelatedPages();
    await load();
  }

  void _invalidateRelatedPages() {
    // 撤销/完成/跳过会影响日历圆点与统计口径，因此需要主动刷新相关页面状态。
    _ref.invalidate(calendarProvider);
    _ref.invalidate(statisticsProvider);
  }

  Future<void> _syncWidget() async {
    try {
      final repo = _ref.read(reviewTaskRepositoryProvider);
      final allToday = await repo.getTasksByDate(DateTime.now());
      final tasks = allToday
          .map(
            (t) => WidgetTaskItem(title: t.title, status: t.status.toDbValue()),
          )
          .toList();

      await WidgetService.updateWidgetData(
        totalCount: state.totalCount,
        completedCount: state.completedCount,
        pendingCount: tasks.where((t) => t.status == 'pending').length,
        tasks: tasks,
      );
    } catch (_) {
      // 小组件同步失败不应影响主流程（如桌面无小组件、插件不可用）。
    }
  }
}

/// 首页任务 Provider。
final homeTasksProvider =
    StateNotifierProvider<HomeTasksNotifier, HomeTasksState>((ref) {
      final notifier = HomeTasksNotifier(ref);
      // 首次创建时加载数据。
      notifier.load();
      return notifier;
    });
