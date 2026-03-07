/// 文件用途：学习目标设置与进度 Provider（统计增强 P0：目标设定）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/goal_settings.dart';
import '../providers/statistics_insights_provider.dart';
import '../providers/statistics_provider.dart';

/// 学习目标设置状态。
class GoalSettingsState {
  /// 构造函数。
  const GoalSettingsState({
    required this.isLoading,
    required this.settings,
    this.errorMessage,
  });

  final bool isLoading;
  final GoalSettingsEntity settings;
  final String? errorMessage;

  factory GoalSettingsState.initial() => GoalSettingsState(
    isLoading: true,
    settings: GoalSettingsEntity.defaults(),
    errorMessage: null,
  );

  GoalSettingsState copyWith({
    bool? isLoading,
    GoalSettingsEntity? settings,
    String? errorMessage,
  }) {
    return GoalSettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }
}

/// 学习目标设置 Notifier。
class GoalSettingsNotifier extends StateNotifier<GoalSettingsState> {
  /// 构造函数。
  GoalSettingsNotifier(this._ref) : super(GoalSettingsState.initial()) {
    load();
  }

  final Ref _ref;

  /// 加载目标设置。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(goalSettingsRepositoryProvider);
      final settings = await repo.getGoalSettings();
      state = state.copyWith(isLoading: false, settings: settings);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 保存目标设置（整体覆盖）。
  Future<void> save(GoalSettingsEntity settings) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(goalSettingsRepositoryProvider);
      await repo.saveGoalSettings(settings);
      state = state.copyWith(isLoading: false, settings: settings);

      // 目标设置变化会影响“目标达成通知/统计展示”，因此刷新统计增强数据。
      _ref.invalidate(statisticsInsightsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

/// 学习目标设置 Provider。
final goalSettingsProvider =
    StateNotifierProvider<GoalSettingsNotifier, GoalSettingsState>((ref) {
      return GoalSettingsNotifier(ref);
    });

/// 目标进度项（供 UI 展示）。
class GoalProgressItem {
  const GoalProgressItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.currentText,
    required this.targetText,
    required this.progress,
    required this.achieved,
  });

  /// 稳定标识（用于列表 key / 动画判定）。
  final String id;

  /// 目标标题。
  final String title;

  /// 辅助说明文本。
  final String subtitle;

  /// 当前值文本（如 “已完成 3”）。
  final String currentText;

  /// 目标值文本（如 “目标 10”）。
  final String targetText;

  /// 进度（0~1）。
  final double progress;

  /// 是否达成。
  final bool achieved;
}

/// 目标进度 Provider。
///
/// 说明：
/// - 进度完全由现有任务统计数据派生，不新增数据库字段
/// - 当统计增强数据尚未加载完成时，返回 loading
final goalProgressProvider = Provider<AsyncValue<List<GoalProgressItem>>>((
  ref,
) {
  final goalState = ref.watch(goalSettingsProvider);
  final stats = ref.watch(statisticsProvider);
  final insightsAsync = ref.watch(statisticsInsightsProvider);

  if (goalState.isLoading) {
    return const AsyncValue.loading();
  }

  return insightsAsync.whenData((insights) {
    final settings = goalState.settings;
    final list = <GoalProgressItem>[];

    // 每日完成数目标：按“今日 done 数量”。
    final dailyTarget = settings.dailyTarget;
    if (dailyTarget != null && dailyTarget > 0) {
      final doneToday = insights.todayStats.doneCount;
      final p = dailyTarget <= 0
          ? 0.0
          : (doneToday / dailyTarget).clamp(0.0, 1.0).toDouble();
      list.add(
        GoalProgressItem(
          id: 'goal_daily',
          title: '每日完成',
          subtitle: '每天完成 $dailyTarget 个任务',
          currentText: '已完成 $doneToday',
          targetText: '目标 $dailyTarget',
          progress: p,
          achieved: doneToday >= dailyTarget,
        ),
      );
    }

    // 连续打卡目标：按连续打卡天数。
    final streakTarget = settings.streakTarget;
    if (streakTarget != null && streakTarget > 0) {
      final current = stats.consecutiveCompletedDays;
      final p = (current / streakTarget).clamp(0.0, 1.0).toDouble();
      list.add(
        GoalProgressItem(
          id: 'goal_streak',
          title: '连续打卡',
          subtitle: '连续学习 $streakTarget 天',
          currentText: '当前 $current 天',
          targetText: '目标 $streakTarget 天',
          progress: p,
          achieved: current >= streakTarget,
        ),
      );
    }

    // 本周完成率目标：按 weekCompletionRate 计算（0~1）。
    final weeklyRateTarget = settings.weeklyRateTarget;
    if (weeklyRateTarget != null && weeklyRateTarget > 0) {
      final currentPercent = (stats.weekCompletionRate * 100)
          .clamp(0.0, 100.0)
          .toDouble();
      final p = (currentPercent / weeklyRateTarget).clamp(0.0, 1.0).toDouble();
      list.add(
        GoalProgressItem(
          id: 'goal_weekly_rate',
          title: '本周完成率',
          subtitle: '本周完成率达到 $weeklyRateTarget%',
          currentText: '当前 ${currentPercent.toStringAsFixed(0)}%',
          targetText: '目标 $weeklyRateTarget%',
          progress: p,
          achieved: currentPercent >= weeklyRateTarget,
        ),
      );
    }

    // 上限 3 个目标（当前设计最多 3 类目标）。
    return list.take(3).toList();
  });
});
