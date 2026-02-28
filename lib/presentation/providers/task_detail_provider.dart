/// 文件用途：任务详情 Sheet 状态管理（加载复习计划、编辑备注、停用、调整计划等）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_item.dart';
import '../../domain/entities/review_task.dart';
import 'calendar_provider.dart';
import 'home_tasks_provider.dart';
import 'statistics_provider.dart';
import 'task_hub_provider.dart';

/// 任务详情状态。
class TaskDetailState {
  const TaskDetailState({
    required this.isLoading,
    required this.item,
    required this.plan,
    this.errorMessage,
  });

  final bool isLoading;
  final LearningItemEntity? item;
  final List<ReviewTaskViewEntity> plan;
  final String? errorMessage;

  factory TaskDetailState.initial() =>
      const TaskDetailState(isLoading: true, item: null, plan: []);

  TaskDetailState copyWith({
    bool? isLoading,
    LearningItemEntity? item,
    List<ReviewTaskViewEntity>? plan,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskDetailState(
      isLoading: isLoading ?? this.isLoading,
      item: item ?? this.item,
      plan: plan ?? this.plan,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 任务详情 Notifier。
class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  TaskDetailNotifier(this._ref, this.learningItemId)
    : super(TaskDetailState.initial()) {
    load();
  }

  final Ref _ref;
  final int learningItemId;

  /// 加载学习内容与复习计划。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final itemRepo = _ref.read(learningItemRepositoryProvider);
      final planUseCase = _ref.read(getReviewPlanUseCaseProvider);

      final itemFuture = itemRepo.getById(learningItemId);
      final planFuture = planUseCase.execute(learningItemId);

      final item = await itemFuture;
      final plan = await planFuture;

      state = state.copyWith(isLoading: false, item: item, plan: plan);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  bool get isReadOnly => (state.item?.isDeleted ?? false);

  Future<void> updateNote(String? note) async {
    await _ref
        .read(updateLearningItemNoteUseCaseProvider)
        .execute(learningItemId: learningItemId, note: note);
    _invalidateRelatedPages();
    await load();
  }

  Future<void> deactivate() async {
    await _ref.read(deactivateLearningItemUseCaseProvider).execute(learningItemId);
    _invalidateRelatedPages();
    await load();
  }

  Future<void> undoTaskStatus(int taskId) async {
    await _ref.read(undoTaskStatusUseCaseProvider).execute(taskId);
    _invalidateRelatedPages();
    await load();
  }

  Future<void> adjustReviewDate({
    required int reviewRound,
    required DateTime newDate,
  }) async {
    await _ref.read(adjustReviewDateUseCaseProvider).execute(
      learningItemId: learningItemId,
      reviewRound: reviewRound,
      newDate: newDate,
    );
    _invalidateRelatedPages();
    await load();
  }

  Future<void> addReviewRound() async {
    await _ref.read(addReviewRoundUseCaseProvider).execute(learningItemId);
    _invalidateRelatedPages();
    await load();
  }

  void _invalidateRelatedPages() {
    _ref.invalidate(homeTasksProvider);
    _ref.invalidate(calendarProvider);
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(taskHubProvider);
  }
}

/// 任务详情 Provider（按 learningItemId family）。
final taskDetailProvider =
    StateNotifierProvider.family<TaskDetailNotifier, TaskDetailState, int>((
  ref,
  learningItemId,
) {
  return TaskDetailNotifier(ref, learningItemId);
});

