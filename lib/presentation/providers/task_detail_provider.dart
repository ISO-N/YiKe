/// 文件用途：任务详情 Sheet 状态管理（加载复习计划、编辑备注、停用、调整计划等）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_item.dart';
import '../../domain/entities/learning_subtask.dart';
import '../../domain/entities/learning_topic.dart';
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
    required this.topics,
    this.errorMessage,
  });

  final bool isLoading;
  final LearningItemEntity? item;
  final List<ReviewTaskViewEntity> plan;
  final List<LearningSubtaskEntity> subtasks;

  /// 关联主题列表（可为空；支持多对多）。
  final List<LearningTopicEntity> topics;
  final String? errorMessage;

  factory TaskDetailState.initial() =>
      const TaskDetailState(
        isLoading: true,
        item: null,
        plan: [],
        subtasks: [],
        topics: [],
      );

  TaskDetailState copyWith({
    bool? isLoading,
    LearningItemEntity? item,
    List<ReviewTaskViewEntity>? plan,
    List<LearningSubtaskEntity>? subtasks,
    List<LearningTopicEntity>? topics,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskDetailState(
      isLoading: isLoading ?? this.isLoading,
      item: item ?? this.item,
      plan: plan ?? this.plan,
      subtasks: subtasks ?? this.subtasks,
      topics: topics ?? this.topics,
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

      // 主题加载失败不应阻塞主流程（例如：主题表尚未初始化/迁移异常等）。
      final topics = await _loadTopicsSafe(learningItemId);

      state = state.copyWith(
        isLoading: false,
        item: item,
        plan: plan,
        subtasks: subtasks,
        topics: topics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  bool get isReadOnly => (state.item?.isDeleted ?? false);

  /// 更新学习内容基础信息（任务名/标签/主题）。
  ///
  /// 说明：
  /// - “任务名/标签”属于 LearningItem 本身
  /// - “主题”属于多对多关联（topic_item_relations）
  /// - 为减少无意义同步日志，仅当确实发生变化时才写入
  Future<void> updateBasicInfo({
    required String title,
    required List<String> tags,
    required Set<int> topicIds,
  }) async {
    if (isReadOnly) {
      throw StateError('学习内容已停用，无法编辑');
    }

    final item = state.item;
    if (item == null) {
      throw StateError('学习内容不存在或尚未加载');
    }

    final normalizedTitle = title.trim();
    final currentTopicIds =
        state.topics.map((e) => e.id).whereType<int>().toSet();

    final shouldUpdateMeta =
        normalizedTitle != item.title || !_sameStringList(tags, item.tags);
    final shouldUpdateTopics = !_sameIntSet(topicIds, currentTopicIds);
    if (!shouldUpdateMeta && !shouldUpdateTopics) return;

    if (shouldUpdateMeta) {
      await _ref.read(updateLearningItemMetaUseCaseProvider).execute(
        learningItemId: learningItemId,
        title: normalizedTitle,
        tags: tags,
      );
    }
    if (shouldUpdateTopics) {
      await _ref.read(setLearningItemTopicsUseCaseProvider).execute(
        learningItemId: learningItemId,
        topicIds: topicIds,
      );
    }

    _invalidateRelatedPages();
    await load();
  }

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

  /// 安全加载某学习内容的关联主题列表（失败时返回空列表）。
  Future<List<LearningTopicEntity>> _loadTopicsSafe(int learningItemId) async {
    try {
      final useCase = _ref.read(manageTopicUseCaseProvider);
      final all = await useCase.getAll();
      return all
          .where((t) => t.id != null && t.itemIds.contains(learningItemId))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      return const <LearningTopicEntity>[];
    }
  }

  /// 判断两个字符串列表是否完全一致（顺序敏感）。
  bool _sameStringList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 判断两个 int 集合是否相等。
  bool _sameIntSet(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
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
