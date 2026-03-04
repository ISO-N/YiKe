/// 文件用途：统计趋势折线图组件（统计增强 P0）——周/月/年视图切换 + tooltip。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/statistics_insights.dart';
import 'glass_card.dart';

/// 统计趋势折线图（完成率）。
///
/// 说明：
/// - 口径：done / (done + pending)（skipped 不计入）
/// - Y 轴固定 0~100
/// - 桌面端 hover 可触发 tooltip（fl_chart 内建支持 PointerHoverEvent）
class StatisticsTrendChart extends StatefulWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [insights] 统计增强数据
  const StatisticsTrendChart({super.key, required this.insights});

  final StatisticsInsightsEntity insights;

  @override
  State<StatisticsTrendChart> createState() => _StatisticsTrendChartState();
}

class _StatisticsTrendChartState extends State<StatisticsTrendChart>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('完成率趋势', style: AppTypography.h2(context)),
                ),
                const Icon(Icons.show_chart, size: 18),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TabBar(
              controller: _controller,
              labelStyle: AppTypography.body(context),
              tabs: const [
                Tab(text: '本周'),
                Tab(text: '本月'),
                Tab(text: '本年'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 220,
              child: TabBarView(
                controller: _controller,
                children: [
                  _Line(points: widget.insights.weekPoints, mode: _TrendMode.day),
                  _Line(
                    points: widget.insights.monthPoints,
                    mode: _TrendMode.day,
                  ),
                  _Line(
                    points: widget.insights.yearPoints,
                    mode: _TrendMode.month,
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

enum _TrendMode { day, month }

class _Line extends StatelessWidget {
  const _Line({required this.points, required this.mode});

  final List<StatisticsTrendPointEntity> points;
  final _TrendMode mode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final gridColor = Theme.of(context).dividerColor.withValues(
      alpha: isDark ? 0.18 : 0.12,
    );

    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final y = points[i].completionRatePercent;
      spots.add(FlSpot(i.toDouble(), y.isNaN ? 0 : y.clamp(0, 100)));
    }

    // 可访问性（spec-user-experience-improvements.md 3.5.1）：
    // fl_chart 本身不提供可遍历的“数据点语义节点”，这里将数据点信息汇总为 Semantics label，
    // 使 TalkBack/VoiceOver 至少能读出当前图表的关键数据。
    return Semantics(
      container: true,
      label: _semanticsLabel(points, mode: mode),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            tooltipBgColor: isDark ? const Color(0xFF0B1220) : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final index = s.x.toInt();
                if (index < 0 || index >= points.length) return null;
                final p = points[index];
                final text = _tooltipText(p, mode: mode);
                return LineTooltipItem(
                  text,
                  TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final v = value.toInt();
                return Text(
                  '$v%',
                  style: AppTypography.bodySecondary(context).copyWith(
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: mode == _TrendMode.month ? 1 : _bottomInterval(points),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _xLabel(points[index].date, mode: mode),
                    style: AppTypography.bodySecondary(context).copyWith(
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: gridColor),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: points.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: primary.withValues(alpha: isDark ? 0.12 : 0.14),
            ),
          ),
          ],
        ),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  double _bottomInterval(List<StatisticsTrendPointEntity> points) {
    // 关键逻辑：按数据量决定 X 轴标签稀疏度，避免本月（最多 31）挤压重叠。
    if (points.length <= 8) return 1;
    if (points.length <= 14) return 2;
    if (points.length <= 21) return 3;
    return 5;
  }

  String _xLabel(DateTime date, {required _TrendMode mode}) {
    switch (mode) {
      case _TrendMode.day:
        return '${date.day}';
      case _TrendMode.month:
        return '${date.month}月';
    }
  }

  String _tooltipText(StatisticsTrendPointEntity p, {required _TrendMode mode}) {
    final total = p.total;
    if (total <= 0) {
      final label = mode == _TrendMode.month
          ? '${p.date.month}月'
          : YikeDateUtils.formatYmd(p.date);
      return '$label: 无任务';
    }
    final rate = p.completionRatePercent.clamp(0, 100).toStringAsFixed(0);
    if (mode == _TrendMode.month) {
      return '${p.date.month}月: ${p.completed}/$total ($rate%)';
    }
    return '${YikeDateUtils.formatYmd(p.date)}: ${p.completed}/$total ($rate%)';
  }

  String _semanticsLabel(
    List<StatisticsTrendPointEntity> points, {
    required _TrendMode mode,
  }) {
    if (points.isEmpty) return '完成率趋势图，无数据';
    final buffer = StringBuffer('完成率趋势图，数据点：');
    for (final p in points) {
      final label = mode == _TrendMode.month
          ? '${p.date.month}月'
          : YikeDateUtils.formatYmd(p.date);
      if (p.total <= 0) {
        buffer.write('$label 无任务；');
        continue;
      }
      final rate = p.completionRatePercent.clamp(0, 100).toStringAsFixed(0);
      buffer.write('$label 完成率 $rate%；');
    }
    return buffer.toString();
  }
}
