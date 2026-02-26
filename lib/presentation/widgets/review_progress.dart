/// 文件用途：首页复习进度展示组件（v3.1 F14.3），包含环形进度与可展开统计信息。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../providers/statistics_provider.dart';
import '../providers/today_progress_provider.dart';
import 'glass_card.dart';

/// 首页复习进度组件。
class ReviewProgressWidget extends ConsumerStatefulWidget {
  /// 构造函数。
  ///
  /// 返回值：组件 Widget。
  /// 异常：无。
  const ReviewProgressWidget({super.key});

  @override
  ConsumerState<ReviewProgressWidget> createState() =>
      _ReviewProgressWidgetState();
}

class _ReviewProgressWidgetState extends ConsumerState<ReviewProgressWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayProgressProvider);
    final stats = ref.watch(statisticsProvider);

    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('今日复习进度', style: AppTypography.h2(context)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              todayAsync.when(
                loading: () => const _ProgressMain(
                  completed: 0,
                  total: 0,
                  showLoading: true,
                ),
                error: (e, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProgressMain(completed: 0, total: 0),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '加载失败：$e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
                data: (t) => _ProgressMain(
                  completed: t.$1,
                  total: t.$2,
                  expanded: _expanded,
                  stats: stats,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressMain extends StatelessWidget {
  const _ProgressMain({
    required this.completed,
    required this.total,
    this.expanded = false,
    this.showLoading = false,
    this.stats,
  });

  final int completed;
  final int total;
  final bool expanded;
  final bool showLoading;
  final StatisticsState? stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    final ringColor = _ringColor(
      primary: primary,
      completed: completed,
      total: total,
    );
    final progress = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    final percentText = total <= 0 ? '0' : (progress * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: ringColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                  Text(
                    '$percentText%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ringColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$completed / $total',
                    style: AppTypography.h2(context).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusText(completed: completed, total: total),
                    style: AppTypography.bodySecondary(context),
                  ),
                ],
              ),
            ),
            if (showLoading)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        if (expanded) ...[
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          _DetailRows(completed: completed, total: total, stats: stats),
        ],
      ],
    );
  }

  Color _ringColor({
    required Color primary,
    required int completed,
    required int total,
  }) {
    // 状态判断：先判断超额完成（预留扩展），再判断已完成/进行中/未开始。
    if (total > 0 && completed > total) return AppColors.cta;
    if (total > 0 && completed >= total) return AppColors.success;
    if (completed > 0 && completed < total) return primary;
    return const Color(0xFF9CA3AF); // Gray
  }

  String _statusText({required int completed, required int total}) {
    if (total <= 0 || completed <= 0) return '未开始';
    if (completed >= total) return '已完成';
    return '进行中';
  }
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({
    required this.completed,
    required this.total,
    required this.stats,
  });

  final int completed;
  final int total;
  final StatisticsState? stats;

  @override
  Widget build(BuildContext context) {
    final week = stats;
    final isLoading = week == null || week.isLoading;

    final weekCompleted = week?.weekCompleted ?? 0;
    final weekTotal = week?.weekTotal ?? 0;
    final monthCompleted = week?.monthCompleted ?? 0;
    final monthTotal = week?.monthTotal ?? 0;
    final streak = week?.consecutiveCompletedDays ?? 0;

    return Column(
      children: [
        _Row(
          title: '今日',
          value: _ratioText(completed, total),
        ),
        const SizedBox(height: 8),
        _Row(
          title: '本周',
          value: isLoading ? '加载中…' : _ratioText(weekCompleted, weekTotal),
        ),
        const SizedBox(height: 8),
        _Row(
          title: '本月',
          value: isLoading ? '加载中…' : _ratioText(monthCompleted, monthTotal),
        ),
        const SizedBox(height: 8),
        _Row(
          title: '连续学习',
          value: isLoading ? '加载中…' : '$streak 天',
        ),
      ],
    );
  }

  String _ratioText(int completed, int total) {
    if (total <= 0) return '$completed/$total (0%)';
    final p = (completed / total * 100).clamp(0, 999).toStringAsFixed(0);
    return '$completed/$total ($p%)';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTypography.bodySecondary(context)),
        ),
        Text(
          value,
          style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

