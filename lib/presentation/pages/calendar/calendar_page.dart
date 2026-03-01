/// 文件用途：日历视图页面（F6），以月历展示每日任务状态并支持点击查看当日任务。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/statistics_sheet.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/compact_stats_bar.dart';
import 'widgets/day_task_list.dart';

/// 日历视图页面（Tab）。
class CalendarPage extends ConsumerStatefulWidget {
  /// 构造函数。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  // 统计 Sheet 打开状态：用于“弹出期间禁用再次触发”以及与当日任务 Sheet 互斥处理。
  bool _isStatsSheetOpen = false;

  // 当日任务 Sheet 打开状态：避免与统计 Sheet 叠加。
  bool _isDaySheetOpen = false;

  // 防止 openStats=1 在同一次构建周期内重复触发。
  bool _didAutoOpenStats = false;

  Future<void> _openStatisticsSheet({
    required bool removeQueryAfterClose,
  }) async {
    // 弹出期间禁用再次触发。
    if (_isStatsSheetOpen) return;

    // Sheet 冲突处理：若当日任务 Sheet 已打开，先关闭再打开统计。
    if (_isDaySheetOpen) {
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);
    }

    setState(() => _isStatsSheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const StatisticsSheet(),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _isStatsSheetOpen = false);
    });

    // openStats=1 触发的自动弹出：关闭后应移除参数，避免返回/重建时重复弹出。
    if (!mounted) return;
    if (removeQueryAfterClose) {
      context.go('/calendar');
    }
  }

  Future<void> _openDayTaskListSheet(DateTime day) async {
    // 若统计 Sheet 已打开，先关闭再打开当日任务 Sheet。
    if (_isStatsSheetOpen) {
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);
    }

    // 若当日任务 Sheet 已打开，先关闭再重新打开（允许用户切换日期）。
    if (_isDaySheetOpen) {
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);
    }

    setState(() => _isDaySheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DayTaskListSheet(
        selectedDay: YikeDateUtils.atStartOfDay(day),
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _isDaySheetOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final openStats = uri.queryParameters['openStats'] == '1';

    if (!openStats) {
      _didAutoOpenStats = false;
    }

    if (openStats && !_didAutoOpenStats) {
      _didAutoOpenStats = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openStatisticsSheet(removeQueryAfterClose: true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.calendar),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: state.isLoadingMonth
                ? null
                : () => notifier.loadMonth(
                    state.focusedMonth.year,
                    state.focusedMonth.month,
                  ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('日历视图', style: AppTypography.h2(context)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '点击日期可查看当日任务列表',
                        style: AppTypography.bodySecondary(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CompactStatsBar(
                        onTap:
                            _isStatsSheetOpen
                                ? null
                                : () => _openStatisticsSheet(
                                  removeQueryAfterClose: false,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CalendarGrid(
                        focusedMonth: state.focusedMonth,
                        selectedDay: state.selectedDay,
                        dayStats: state.monthStats,
                        isLoading: state.isLoadingMonth,
                        onPageChanged: (focused) =>
                            notifier.loadMonth(focused.year, focused.month),
                        onDaySelected: (day) async {
                          await notifier.selectDay(day);
                          if (!context.mounted) return;
                          await _openDayTaskListSheet(day);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _LegendCard(),
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
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态说明', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                const _LegendItem(color: AppColors.warning, text: '有逾期任务'),
                _LegendItem(color: primary, text: '有待复习任务'),
                const _LegendItem(color: AppColors.success, text: '已处理（完成/跳过）'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.bodySecondary(context)),
      ],
    );
  }
}
