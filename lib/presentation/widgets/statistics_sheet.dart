/// 文件用途：统计详情 Bottom Sheet（复用 StatisticsContent）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../providers/statistics_provider.dart';
import 'gradient_background.dart';
import 'statistics_content.dart';

/// 统计详情 Sheet。
///
/// 说明：
/// - 用于日历页顶部 CompactStatsBar 的展开详情。
/// - 通过复用 [StatisticsContent] 避免复制粘贴统计页面 UI。
class StatisticsSheet extends ConsumerWidget {
  /// 构造函数。
  ///
  /// 返回值：Widget。
  /// 异常：无。
  const StatisticsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);
    final notifier = ref.read(statisticsProvider.notifier);

    return GradientBackground(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '统计详情',
                      style: AppTypography.h2(context),
                    ),
                  ),
                  IconButton(
                    tooltip: '刷新',
                    onPressed: state.isLoading ? null : () => notifier.load(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StatisticsContent(
                state: state,
                onRefresh: notifier.load,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

