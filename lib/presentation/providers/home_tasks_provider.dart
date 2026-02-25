/// 文件用途：首页任务状态管理（Riverpod StateNotifier）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/review_task.dart';
import '../../infrastructure/widget/widget_service.dart';

/// 首页任务状态。
class HomeTasksState {
  /// 构造函数。
  const HomeTasksState({
    required this.isLoading,
    required this.todayPending,
    required this.overduePending,
    required this.completedCount,
    required this.totalCount,
    required this.isSelectionMode,
    required this.selectedTaskIds,
    this.errorMessage,
  });

  final bool isLoading;
  final List<ReviewTaskViewEntity> todayPending;
  final List<ReviewTaskViewEntity> overduePending;
  final int completedCount;
  final int totalCount;
  final bool isSelectionMode;
  final Set<int> selectedTaskIds;
  final String? errorMessage;

  factory HomeTasksState.initial() => const HomeTasksState(
        isLoading: true,
        todayPending: [],
        overduePending: [],
        completedCount: 0,
        totalCount: 0,
        isSelectionMode: false,
        selectedTaskIds: {},
      );

  HomeTasksState copyWith({
    bool? isLoading,
    List<ReviewTaskViewEntity>? todayPending,
    List<ReviewTaskViewEntity>? overduePending,
    int? completedCount,
    int? totalCount,
    bool? isSelectionMode,
    Set<int>? selectedTaskIds,
    String? errorMessage,
  }) {
    return HomeTasksState(
      isLoading: isLoading ?? this.isLoading,
      todayPending: todayPending ?? this.todayPending,
      overduePending: overduePending ?? this.overduePending,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
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
      final result = await useCase.execute();
      state = state.copyWith(
        isLoading: false,
        todayPending: result.todayPending,
        overduePending: result.overduePending,
        completedCount: result.completedCount,
        totalCount: result.totalCount,
      );

      // 同步桌面小组件数据（v1.0 Android 展示）。
      await _syncWidget();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 开关选择模式（用于批量完成/跳过）。
  void toggleSelectionMode() {
    if (state.isSelectionMode) {
      state = state.copyWith(isSelectionMode: false, selectedTaskIds: <int>{});
    } else {
      state = state.copyWith(isSelectionMode: true, selectedTaskIds: <int>{});
    }
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
    await load();
  }

  /// 跳过单个任务。
  Future<void> skipTask(int taskId) async {
    final useCase = _ref.read(skipReviewTaskUseCaseProvider);
    await useCase.execute(taskId);
    await load();
  }

  /// 批量完成所选任务。
  Future<void> completeSelected() async {
    final ids = state.selectedTaskIds.toList();
    if (ids.isEmpty) return;
    final useCase = _ref.read(completeReviewTaskUseCaseProvider);
    await useCase.executeBatch(ids);
    state = state.copyWith(isSelectionMode: false, selectedTaskIds: <int>{});
    await load();
  }

  /// 批量跳过所选任务。
  Future<void> skipSelected() async {
    final ids = state.selectedTaskIds.toList();
    if (ids.isEmpty) return;
    final useCase = _ref.read(skipReviewTaskUseCaseProvider);
    await useCase.executeBatch(ids);
    state = state.copyWith(isSelectionMode: false, selectedTaskIds: <int>{});
    await load();
  }

  Future<void> _syncWidget() async {
    try {
      final repo = _ref.read(reviewTaskRepositoryProvider);
      final allToday = await repo.getTasksByDate(DateTime.now());
      final tasks = allToday
          .map(
            (t) => WidgetTaskItem(
              title: t.title,
              status: t.status.toDbValue(),
            ),
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
final homeTasksProvider = StateNotifierProvider<HomeTasksNotifier, HomeTasksState>((ref) {
  final notifier = HomeTasksNotifier(ref);
  // 首次创建时加载数据。
  notifier.load();
  return notifier;
});
