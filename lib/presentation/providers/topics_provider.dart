/// 文件用途：主题状态管理（Riverpod StateNotifier），用于主题 CRUD 与概览加载（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_topic.dart';
import '../../domain/entities/learning_topic_overview.dart';
import '../../domain/usecases/manage_topic_usecase.dart';

/// 主题列表状态（概览）。
class TopicsState {
  const TopicsState({
    required this.isLoading,
    required this.overviews,
    this.errorMessage,
  });

  final bool isLoading;
  final List<LearningTopicOverviewEntity> overviews;
  final String? errorMessage;

  factory TopicsState.initial() => const TopicsState(
    isLoading: true,
    overviews: [],
  );

  TopicsState copyWith({
    bool? isLoading,
    List<LearningTopicOverviewEntity>? overviews,
    String? errorMessage,
  }) {
    return TopicsState(
      isLoading: isLoading ?? this.isLoading,
      overviews: overviews ?? this.overviews,
      errorMessage: errorMessage,
    );
  }
}

/// 主题 Notifier。
class TopicsNotifier extends StateNotifier<TopicsState> {
  TopicsNotifier(this._useCase) : super(TopicsState.initial());

  final ManageTopicUseCase _useCase;

  /// 加载主题概览。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _useCase.getOverviews();
      state = state.copyWith(isLoading: false, overviews: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 创建主题。
  Future<LearningTopicEntity> create(TopicParams params) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _useCase.create(params);
      final list = await _useCase.getOverviews();
      state = state.copyWith(isLoading: false, overviews: list);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// 更新主题。
  Future<LearningTopicEntity> update(
    LearningTopicEntity topic,
    TopicParams params,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _useCase.update(
        topic.id!,
        params,
        createdAt: topic.createdAt,
      );
      final list = await _useCase.getOverviews();
      state = state.copyWith(isLoading: false, overviews: list);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// 删除主题。
  Future<void> delete(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _useCase.delete(id);
      final list = await _useCase.getOverviews();
      state = state.copyWith(isLoading: false, overviews: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

/// 主题 Provider。
final topicsProvider =
    StateNotifierProvider<TopicsNotifier, TopicsState>((ref) {
      final useCase = ref.read(manageTopicUseCaseProvider);
      final notifier = TopicsNotifier(useCase);
      notifier.load();
      return notifier;
    });

