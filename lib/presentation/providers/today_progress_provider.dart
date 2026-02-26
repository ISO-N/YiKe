/// 文件用途：首页今日复习进度 Provider（v3.1 F14.3），提供 (completed,total) 数据。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import 'home_tasks_provider.dart';

/// 今日复习进度 Provider（completed/total）。
///
/// 说明：
/// - 数据源为 ReviewTaskDao.getTaskStats（通过仓储层调用）
/// - 依赖 homeTasksProvider 的刷新，用于在任务状态变化后自动触发重新计算
final todayProgressProvider =
    FutureProvider.autoDispose<(int completed, int total)>((ref) async {
      // 监听首页任务状态变化（完成/跳过后会触发 reload）。
      ref.watch(
        homeTasksProvider.select(
          (s) => (s.isLoading, s.completedCount, s.totalCount),
        ),
      );

      final repo = ref.read(reviewTaskRepositoryProvider);
      return repo.getTaskStats(DateTime.now());
    });
