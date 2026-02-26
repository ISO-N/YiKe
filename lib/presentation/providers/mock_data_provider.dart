/// 文件用途：模拟数据生成器状态管理（v3.1 Debug），负责生成/清理任务并驱动 UI。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../infrastructure/debug/mock_data_service.dart';
import 'calendar_provider.dart';
import 'home_tasks_provider.dart';
import 'statistics_provider.dart';

/// Mock 数据 UI 状态。
class MockDataUiState {
  const MockDataUiState({
    required this.isRunning,
    required this.contentCount,
    required this.taskCount,
    required this.daysRange,
    required this.template,
    required this.customPrefix,
    this.message,
    this.errorMessage,
  });

  final bool isRunning;
  final int contentCount;
  final int taskCount;
  final int daysRange;
  final MockDataTemplate template;
  final String customPrefix;
  final String? message;
  final String? errorMessage;

  factory MockDataUiState.initial() => const MockDataUiState(
    isRunning: false,
    contentCount: 10,
    taskCount: 50,
    daysRange: 30,
    template: MockDataTemplate.random,
    customPrefix: '自定义',
  );

  MockDataUiState copyWith({
    bool? isRunning,
    int? contentCount,
    int? taskCount,
    int? daysRange,
    MockDataTemplate? template,
    String? customPrefix,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return MockDataUiState(
      isRunning: isRunning ?? this.isRunning,
      contentCount: contentCount ?? this.contentCount,
      taskCount: taskCount ?? this.taskCount,
      daysRange: daysRange ?? this.daysRange,
      template: template ?? this.template,
      customPrefix: customPrefix ?? this.customPrefix,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  MockDataConfig toConfig() => MockDataConfig(
    contentCount: contentCount,
    taskCount: taskCount,
    daysRange: daysRange,
    template: template,
    customPrefix: customPrefix,
  );
}

/// Mock 数据 Notifier。
class MockDataNotifier extends StateNotifier<MockDataUiState> {
  MockDataNotifier(this._ref) : super(MockDataUiState.initial());

  final Ref _ref;

  void setContentCount(int v) {
    state = state.copyWith(contentCount: v, clearMessage: true, clearError: true);
  }

  void setTaskCount(int v) {
    state = state.copyWith(taskCount: v, clearMessage: true, clearError: true);
  }

  void setDaysRange(int v) {
    state = state.copyWith(daysRange: v, clearMessage: true, clearError: true);
  }

  void setTemplate(MockDataTemplate v) {
    state = state.copyWith(template: v, clearMessage: true, clearError: true);
  }

  void setCustomPrefix(String v) {
    state = state.copyWith(customPrefix: v, clearMessage: true, clearError: true);
  }

  /// 生成模拟数据。
  Future<void> generate() async {
    state = state.copyWith(isRunning: true, clearMessage: true, clearError: true);
    try {
      final service = _ref.read(mockDataServiceProvider);
      final result = await service.generate(state.toConfig());
      state = state.copyWith(
        isRunning: false,
        message: '已生成：学习内容 ${result.insertedItemCount} 条，复习任务 ${result.insertedTaskCount} 条',
      );

      // 生成后刷新核心页面状态。
      _invalidateUiData();
    } catch (e) {
      state = state.copyWith(isRunning: false, errorMessage: e.toString());
    }
  }

  /// 清理模拟数据（按 isMockData=true）。
  Future<void> clearMockData() async {
    state = state.copyWith(isRunning: true, clearMessage: true, clearError: true);
    try {
      final service = _ref.read(mockDataServiceProvider);
      final (deletedItems, deletedTasks) = await service.clearMockData();
      state = state.copyWith(
        isRunning: false,
        message: '已清理：学习内容 $deletedItems 条，复习任务 $deletedTasks 条',
      );
      _invalidateUiData();
    } catch (e) {
      state = state.copyWith(isRunning: false, errorMessage: e.toString());
    }
  }

  /// 清空全部数据（危险操作）。
  Future<void> clearAllData() async {
    state = state.copyWith(isRunning: true, clearMessage: true, clearError: true);
    try {
      final service = _ref.read(mockDataServiceProvider);
      await service.clearAllData();
      state = state.copyWith(isRunning: false, message: '已清空全部业务数据（设置项保留）');
      _invalidateUiData();
    } catch (e) {
      state = state.copyWith(isRunning: false, errorMessage: e.toString());
    }
  }

  void _invalidateUiData() {
    // 首页
    _ref.invalidate(homeTasksProvider);
    // 日历
    _ref.invalidate(calendarProvider);
    // 统计
    _ref.invalidate(statisticsProvider);
  }
}

/// MockDataService Provider。
final mockDataServiceProvider = Provider<MockDataService>((ref) {
  return MockDataService(
    db: ref.read(appDatabaseProvider),
    learningItemDao: ref.read(learningItemDaoProvider),
    reviewTaskDao: ref.read(reviewTaskDaoProvider),
  );
});

/// 模拟数据生成器 Provider。
final mockDataProvider = StateNotifierProvider<MockDataNotifier, MockDataUiState>(
  (ref) => MockDataNotifier(ref),
);

