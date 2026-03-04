/// 文件用途：统计热力图数据 Provider（按年查询每日完成率口径数据）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/task_day_stats.dart';

/// 统计热力图数据 Provider（按年）。
///
/// 说明：
/// - 口径按 scheduledDate 聚合到自然日
/// - key 为当天 00:00:00
final statisticsHeatmapProvider =
    FutureProvider.family<Map<DateTime, TaskDayStats>, int>((ref, year) async {
      final repo = ref.read(reviewTaskRepositoryProvider);
      final start = DateTime(year, 1, 1);
      final end = DateTime(year + 1, 1, 1);
      return repo.getTaskDayStatsInRange(start, end);
    });

