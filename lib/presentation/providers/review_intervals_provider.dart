/// 文件用途：复习间隔配置状态管理（Riverpod StateNotifier），用于复习预览与新内容生成（F1.5）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/review_interval_config.dart';
import '../../domain/repositories/settings_repository.dart';

/// 复习间隔配置状态。
class ReviewIntervalsState {
  const ReviewIntervalsState({
    required this.isLoading,
    required this.configs,
    this.errorMessage,
  });

  final bool isLoading;
  final List<ReviewIntervalConfigEntity> configs;
  final String? errorMessage;

  factory ReviewIntervalsState.initial() =>
      const ReviewIntervalsState(isLoading: true, configs: []);

  ReviewIntervalsState copyWith({
    bool? isLoading,
    List<ReviewIntervalConfigEntity>? configs,
    String? errorMessage,
  }) {
    return ReviewIntervalsState(
      isLoading: isLoading ?? this.isLoading,
      configs: configs ?? this.configs,
      errorMessage: errorMessage,
    );
  }
}

/// 复习间隔配置 Notifier。
class ReviewIntervalsNotifier extends StateNotifier<ReviewIntervalsState> {
  ReviewIntervalsNotifier(this._repository)
    : super(ReviewIntervalsState.initial());

  final SettingsRepository _repository;

  /// 加载配置。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final configs = await _repository.getReviewIntervalConfigs();
      state = state.copyWith(isLoading: false, configs: configs);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 保存配置（并持久化到设置表）。
  Future<void> save(List<ReviewIntervalConfigEntity> configs) async {
    state = state.copyWith(isLoading: true, errorMessage: null, configs: configs);
    try {
      await _repository.saveReviewIntervalConfigs(configs);
      state = state.copyWith(isLoading: false, configs: configs);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// 更新指定轮次配置并保存。
  Future<void> updateRound(
    int round, {
    int? intervalDays,
    bool? enabled,
  }) async {
    final next = state.configs.map((c) {
      if (c.round != round) return c;
      return c.copyWith(
        intervalDays: intervalDays ?? c.intervalDays,
        enabled: enabled ?? c.enabled,
      );
    }).toList();

    // 保护：至少保留一轮复习。
    if (!next.any((e) => e.enabled)) {
      throw ArgumentError('至少保留一轮复习');
    }

    await save(next);
  }

  /// 恢复默认（艾宾浩斯）。
  Future<void> resetDefault() async {
    const defaults = [1, 2, 4, 7, 15];
    final next = List<ReviewIntervalConfigEntity>.generate(
      defaults.length,
      (index) => ReviewIntervalConfigEntity(
        round: index + 1,
        intervalDays: defaults[index],
        enabled: true,
      ),
    );
    await save(next);
  }

  /// 启用全部轮次。
  Future<void> enableAll() async {
    final next = state.configs.map((c) => c.copyWith(enabled: true)).toList();
    await save(next);
  }
}

/// 复习间隔配置 Provider。
final reviewIntervalsProvider =
    StateNotifierProvider<ReviewIntervalsNotifier, ReviewIntervalsState>((ref) {
      final repo = ref.read(settingsRepositoryProvider);
      final notifier = ReviewIntervalsNotifier(repo);
      notifier.load();
      return notifier;
    });

