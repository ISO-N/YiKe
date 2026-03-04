/// 文件用途：UI 本地偏好状态管理（Riverpod），用于保存/读取“性能相关的 UI 开关”等本机偏好。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/repositories/ui_preferences_repository.dart';

/// 任务列表毛玻璃效果开关 Notifier（默认开启，可关闭以提升滚动流畅度）。
class TaskListBlurNotifier extends StateNotifier<bool> {
  /// 构造函数。
  ///
  /// 参数：
  /// - [repository] UI 偏好仓储
  TaskListBlurNotifier(this._repository) : super(true) {
    _load();
  }

  final UiPreferencesRepository _repository;

  /// 启动时加载本地偏好。
  ///
  /// 说明：读取失败时保持默认 true，避免因异常导致 UI 退化。
  Future<void> _load() async {
    state = await _repository.getTaskListBlurEnabled();
  }

  /// 更新开关并持久化。
  ///
  /// 参数：
  /// - [enabled] 是否启用毛玻璃
  /// 返回值：Future（无返回值）
  /// 异常：写入失败时会抛出异常，由上层 UI 兜底提示
  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    await _repository.setTaskListBlurEnabled(enabled);
  }
}

/// 任务列表毛玻璃效果开关 Provider。
final taskListBlurEnabledProvider = StateNotifierProvider<TaskListBlurNotifier, bool>((
  ref,
) {
  final repo = ref.read(uiPreferencesRepositoryProvider);
  return TaskListBlurNotifier(repo);
});

/// 撤销 Snackbar 开关 Notifier（默认开启）。
class UndoSnackbarNotifier extends StateNotifier<bool> {
  /// 构造函数。
  ///
  /// 参数：
  /// - [repository] UI 偏好仓储
  UndoSnackbarNotifier(this._repository) : super(true) {
    _load();
  }

  final UiPreferencesRepository _repository;

  Future<void> _load() async {
    state = await _repository.getUndoSnackbarEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    await _repository.setUndoSnackbarEnabled(enabled);
  }
}

/// 撤销 Snackbar 开关 Provider。
final undoSnackbarEnabledProvider =
    StateNotifierProvider<UndoSnackbarNotifier, bool>((ref) {
      final repo = ref.read(uiPreferencesRepositoryProvider);
      return UndoSnackbarNotifier(repo);
    });

/// 触觉反馈开关 Notifier（默认开启）。
class HapticFeedbackNotifier extends StateNotifier<bool> {
  /// 构造函数。
  ///
  /// 参数：
  /// - [repository] UI 偏好仓储
  HapticFeedbackNotifier(this._repository) : super(true) {
    _load();
  }

  final UiPreferencesRepository _repository;

  Future<void> _load() async {
    state = await _repository.getHapticFeedbackEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    await _repository.setHapticFeedbackEnabled(enabled);
  }
}

/// 触觉反馈开关 Provider。
final hapticFeedbackEnabledProvider =
    StateNotifierProvider<HapticFeedbackNotifier, bool>((ref) {
      final repo = ref.read(uiPreferencesRepositoryProvider);
      return HapticFeedbackNotifier(repo);
    });

/// 骨架屏策略 Notifier（"auto" | "on" | "off"）。
class SkeletonStrategyNotifier extends StateNotifier<String> {
  /// 构造函数。
  ///
  /// 参数：
  /// - [repository] UI 偏好仓储
  SkeletonStrategyNotifier(this._repository) : super('auto') {
    _load();
  }

  final UiPreferencesRepository _repository;

  Future<void> _load() async {
    state = await _repository.getSkeletonStrategy();
  }

  Future<void> setStrategy(String strategy) async {
    if (state == strategy) return;
    state = strategy;
    await _repository.setSkeletonStrategy(strategy);
  }
}

/// 骨架屏策略 Provider。
final skeletonStrategyProvider =
    StateNotifierProvider<SkeletonStrategyNotifier, String>((ref) {
      final repo = ref.read(uiPreferencesRepositoryProvider);
      return SkeletonStrategyNotifier(repo);
    });

