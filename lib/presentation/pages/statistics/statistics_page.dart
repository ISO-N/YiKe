/// 文件用途：学习统计页面（F7）——作为独立页面保留，统计内容由可复用组件承载。
/// 作者：Codex
/// 创建日期：2026-02-25
/// 最后更新：2026-03-01（抽离 StatisticsContent 以供 Sheet 复用）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/statistics_content.dart';

/// 统计页面（独立页面）。
///
/// 说明：
/// - v3.2 UI 精简后，统计入口主要通过“日历页顶部统计栏 → Sheet”触达。
/// - 该页面保留用于复杂场景/桌面端/调试时的全屏查看，避免强行 Sheet 化。
class StatisticsPage extends ConsumerWidget {
  /// 构造函数。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);
    final notifier = ref.read(statisticsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.statistics),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: state.isLoading ? null : () => notifier.load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: StatisticsContent(state: state, onRefresh: notifier.load),
        ),
      ),
    );
  }
}

