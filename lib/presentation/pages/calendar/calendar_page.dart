/// 文件用途：日历视图页面（F6），以月历展示每日任务状态并支持点击查看当日任务。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/day_task_list.dart';

/// 日历视图页面（Tab）。
class CalendarPage extends ConsumerWidget {
  /// 构造函数。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

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
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => DayTaskListSheet(
                              selectedDay: YikeDateUtils.atStartOfDay(day),
                            ),
                          );
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
                const _LegendItem(
                  color: AppColors.success,
                  text: '已处理（完成/跳过）',
                ),
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
