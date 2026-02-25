/// 文件用途：日历网格组件（基于 table_calendar），支持月份翻页与单日状态圆点标记。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/task_day_stats.dart';

/// 日历网格组件。
class CalendarGrid extends StatelessWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [focusedMonth] 当前聚焦月份
  /// - [selectedDay] 当前选中日期
  /// - [dayStats] 月份单日统计（key 为当天 00:00）
  /// - [isLoading] 是否加载中
  /// - [onPageChanged] 翻页回调
  /// - [onDaySelected] 选中日期回调
  const CalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.dayStats,
    required this.isLoading,
    required this.onPageChanged,
    required this.onDaySelected,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<DateTime, TaskDayStats> dayStats;
  final bool isLoading;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final todayStart = YikeDateUtils.atStartOfDay(DateTime.now());

    return TableCalendar<TaskDayStats>(
      firstDay: DateTime(2000, 1, 1),
      lastDay: DateTime(2100, 12, 31),
      focusedDay: focusedMonth,
      selectedDayPredicate: (day) {
        final selected = selectedDay;
        if (selected == null) return false;
        return YikeDateUtils.isSameDay(day, selected);
      },
      availableCalendarFormats: const {CalendarFormat.month: '月'},
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      rowHeight: 48,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left),
        rightChevronIcon: Icon(Icons.chevron_right),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withAlpha(36),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      eventLoader: (day) {
        final key = YikeDateUtils.atStartOfDay(day);
        final stats = dayStats[key];
        if (stats == null || stats.totalCount == 0) return const [];
        return [stats];
      },
      calendarBuilders: CalendarBuilders<TaskDayStats>(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          final key = YikeDateUtils.atStartOfDay(day);
          final stats = dayStats[key];
          if (stats == null || stats.totalCount == 0) return null;
          final color = _markerColor(
            stats: stats,
            dayStart: key,
            todayStart: todayStart,
          );
          if (color == null) return null;
          return Padding(
            padding: const EdgeInsets.only(top: 34),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          );
        },
      ),
      onDaySelected: (selected, focused) => onDaySelected(selected),
      onPageChanged: onPageChanged,
    );
  }

  /// 根据 PRD 规则计算当日圆点颜色。
  ///
  /// 优先级：逾期 > 待复习 > 已处理（完成/跳过）。
  Color? _markerColor({
    required TaskDayStats stats,
    required DateTime dayStart,
    required DateTime todayStart,
  }) {
    if (stats.totalCount == 0) return null;

    final isPastDay = dayStart.isBefore(todayStart);
    final hasOverdue = stats.pendingCount > 0 && isPastDay;
    if (hasOverdue) return AppColors.warning;

    if (stats.pendingCount > 0) return AppColors.primary;

    // 无 pending 视为“已处理”（done 或 skipped）。
    return AppColors.success;
  }
}
