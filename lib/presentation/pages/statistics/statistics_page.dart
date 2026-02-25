/// 文件用途：学习统计页面（F7），展示连续打卡、本周/本月完成率与标签分布饼图。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/glass_card.dart';

/// 统计页面（Tab）。
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6FFFB),
              Color(0xFFF0FDFA),
              Color(0xFFFFF7ED),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _StreakCard(days: state.consecutiveCompletedDays),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _CompletionCard(
                      title: '本周',
                      completed: state.weekCompleted,
                      total: state.weekTotal,
                      rate: state.weekCompletionRate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _CompletionCard(
                      title: '本月',
                      completed: state.monthCompleted,
                      total: state.monthTotal,
                      rate: state.monthCompletionRate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _TagPieChart(distribution: state.tagDistribution),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('加载失败：${state.errorMessage}', style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
              if (state.isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cta.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cta.withAlpha(80)),
              ),
              child: const Icon(Icons.local_fire_department, color: AppColors.cta),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('连续打卡', style: AppTypography.h2),
                  const SizedBox(height: 4),
                  Text(
                    days == 0 ? '还没有形成连续打卡' : '已连续打卡 $days 天',
                    style: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.title,
    required this.completed,
    required this.total,
    required this.rate,
  });

  final String title;
  final int completed;
  final int total;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).clamp(0, 100).toStringAsFixed(0);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: SizedBox(
                width: 96,
                height: 96,
                child: _RingProgress(rate: rate),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                '$percent%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '$completed / $total',
                style: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingProgress extends StatelessWidget {
  const _RingProgress({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final v = rate.clamp(0, 1);
    final remaining = (1 - v).clamp(0, 1);

    return PieChart(
      PieChartData(
        startDegreeOffset: -90,
        sectionsSpace: 0,
        centerSpaceRadius: 34,
        sections: [
          PieChartSectionData(
            value: remaining * 100,
            color: AppColors.primary.withAlpha(18),
            radius: 12,
            showTitle: false,
          ),
          PieChartSectionData(
            value: v * 100,
            color: AppColors.primary,
            radius: 12,
            showTitle: false,
          ),
        ],
      ),
    );
  }
}

class _TagPieChart extends StatelessWidget {
  const _TagPieChart({required this.distribution});

  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.where((e) => e.key.trim().isNotEmpty && e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('标签分布', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              entries.isEmpty ? '还没有标签分类' : '按学习内容标签统计占比（多标签会重复计数）',
              style: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: const [
                    Icon(Icons.pie_chart_outline, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: AppSpacing.md),
                    Text('暂无数据', style: AppTypography.bodySecondary),
                  ],
                ),
              )
            else
              _PieWithLegend(entries: entries),
          ],
        ),
      ),
    );
  }
}

class _PieWithLegend extends StatelessWidget {
  const _PieWithLegend({required this.entries});

  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    final palette = _palette();
    final sections = <PieChartSectionData>[];

    for (var i = 0; i < entries.length; i++) {
      final color = palette[i % palette.length];
      final v = entries[i].value.toDouble();
      sections.add(
        PieChartSectionData(
          value: v,
          color: color,
          radius: 18,
          showTitle: false,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 38,
              startDegreeOffset: -90,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < entries.length; i++) ...[
          _LegendRow(
            color: palette[i % palette.length],
            title: entries[i].key,
            value: entries[i].value,
            percent: total == 0 ? 0 : (entries[i].value / total) * 100,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<Color> _palette() {
    return const [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.cta,
      Color(0xFF6366F1), // Indigo
      Color(0xFF0EA5E9), // Sky
      Color(0xFFA855F7), // Purple
      Color(0xFFEC4899), // Pink
    ];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.title,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String title;
  final int value;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final p = percent.isNaN ? 0 : percent;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: AppTypography.bodySecondary, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value · ${p.toStringAsFixed(1)}%',
          style: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
