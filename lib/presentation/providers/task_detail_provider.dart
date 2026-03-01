/// 文件用途：任务详情 Sheet 状态管理（加载复习计划、编辑备注、停用、调整计划等）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_item.dart';
import '../../domain/entities/learning_subtask.dart';
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
    required this.subtasks,
    this.errorMessage,
  });

  final bool isLoading;
  final LearningItemEntity? item;
  final List<ReviewTaskViewEntity> plan;
  final List<LearningSubtaskEntity> subtasks;
  final String? errorMessage;

  factory TaskDetailState.initial() =>
      const TaskDetailState(
        isLoading: true,
        item: null,
        plan: [],
        subtasks: [],
      );

  TaskDetailState copyWith({
    bool? isLoading,
    LearningItemEntity? item,
    List<ReviewTaskViewEntity>? plan,
    List<LearningSubtaskEntity>? subtasks,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskDetailState(
      isLoading: isLoading ?? this.isLoading,
      item: item ?? this.item,
      plan: plan ?? this.plan,
      subtasks: subtasks ?? this.subtasks,
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
      final subtaskRepo = _ref.read(learningSubtaskRepositoryProvider);
      final planUseCase = _ref.read(getReviewPlanUseCaseProvider);

      final itemFuture = itemRepo.getById(learningItemId);
      final planFuture = planUseCase.execute(learningItemId);
      final subtasksFuture = subtaskRepo.getByLearningItemId(learningItemId);

      final item = await itemFuture;
      final plan = await planFuture;
      final subtasks = await subtasksFuture;

      state = state.copyWith(
        isLoading: false,
        item: item,
        plan: plan,
        subtasks: subtasks,
      );
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

  Future<void> updateDescription(String? description) async {
    await _ref
        .read(updateLearningItemDescriptionUseCaseProvider)
        .execute(learningItemId: learningItemId, description: description);
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

  Future<void> removeReviewRound() async {
    await _ref.read(removeReviewRoundUseCaseProvider).execute(learningItemId);
    _invalidateRelatedPages();
    await load();
  }

  Future<void> createSubtask(String content) async {
    await _ref.read(createSubtaskUseCaseProvider).execute(
      learningItemId: learningItemId,
      content: content,
    );
    _invalidateRelatedPages();
    await load();
  }

  Future<void> updateSubtask(LearningSubtaskEntity subtask) async {
    await _ref.read(updateSubtaskUseCaseProvider).execute(subtask);
    _invalidateRelatedPages();
    await load();
  }

  Future<void> deleteSubtask(int id) async {
    await _ref.read(deleteSubtaskUseCaseProvider).execute(id);
    _invalidateRelatedPages();
    await load();
  }

  Future<void> reorderSubtasks(List<int> subtaskIds) async {
    await _ref.read(reorderSubtasksUseCaseProvider).execute(
      learningItemId: learningItemId,
      subtaskIds: subtaskIds,
    );
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
