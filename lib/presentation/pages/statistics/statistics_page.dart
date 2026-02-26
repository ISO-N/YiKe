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
import '../../widgets/gradient_background.dart';

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
      body: GradientBackground(
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
                    child: Text(
                      '加载失败：${state.errorMessage}',
                      style: const TextStyle(color: AppColors.error),
                    ),
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
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.cta,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('连续打卡', style: AppTypography.h2(context)),
                  const SizedBox(height: 4),
                  Text(
                    days == 0 ? '还没有形成连续打卡' : '已连续打卡 $days 天',
                    style: AppTypography.bodySecondary(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    final percent = (rate * 100).clamp(0, 100).toStringAsFixed(0);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h2(context)),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '$completed / $total',
                style: AppTypography.bodySecondary(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

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
            color: primary.withValues(alpha: 0.18),
            radius: 12,
            showTitle: false,
          ),
          PieChartSectionData(
            value: v * 100,
            color: primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final entries =
        distribution.entries
            .where((e) => e.key.trim().isNotEmpty && e.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标签分布', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              entries.isEmpty ? '还没有标签分类' : '按学习内容标签统计占比（多标签会重复计数）',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: secondaryText,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('暂无数据', style: AppTypography.bodySecondary(context)),
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

class _PieWithLegend extends StatefulWidget {
  const _PieWithLegend({required this.entries});

  final List<MapEntry<String, int>> entries;

  @override
  State<_PieWithLegend> createState() => _PieWithLegendState();
}

class _PieWithLegendState extends State<_PieWithLegend> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tooltipBackground = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tooltipTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    final entries = widget.entries;
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    final palette = _palette(isDark: isDark);
    final sections = <PieChartSectionData>[];

    for (var i = 0; i < entries.length; i++) {
      final color = palette[i % palette.length];
      final v = entries[i].value.toDouble();
      final isTouched = _touchedIndex == i;
      final percent = total == 0 ? 0.0 : (entries[i].value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: v,
          color: color,
          radius: isTouched ? 22 : 18,
          showTitle: false,
          badgeWidget: isTouched
              ? _PieTooltip(
                  text:
                      '${entries[i].key} · ${entries[i].value}（${percent.toStringAsFixed(1)}%）',
                  backgroundColor: tooltipBackground,
                  textColor: tooltipTextColor,
                )
              : null,
          badgePositionPercentageOffset: 1.18,
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
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions) {
                      _touchedIndex = null;
                      return;
                    }
                    final index =
                        response?.touchedSection?.touchedSectionIndex ?? -1;
                    _touchedIndex = index < 0 ? null : index;
                  });
                },
              ),
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

  List<Color> _palette({required bool isDark}) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return [
      primary,
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

class _PieTooltip extends StatelessWidget {
  const _PieTooltip({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
          child: Text(
            title,
            style: AppTypography.bodySecondary(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value · ${p.toStringAsFixed(1)}%',
          style: AppTypography.bodySecondary(context),
        ),
      ],
    );
  }
}
