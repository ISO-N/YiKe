/// 文件用途：统计增强数据 Provider（趋势图/热力图/对比分析），供统计页面与统计 Sheet 使用。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/statistics_insights.dart';

/// 统计增强数据 Provider。
///
/// 说明：
/// - 与 [statisticsProvider]（统计摘要）分离：避免热力图等重数据阻塞顶部统计栏渲染。
/// - 默认以“今天”为基准计算本周/本月/本年的趋势口径。
final statisticsInsightsProvider = FutureProvider<StatisticsInsightsEntity>((
  ref,
) async {
  final useCase = ref.read(getStatisticsInsightsUseCaseProvider);
  return useCase.execute();
});
