/// 文件用途：CSV 导出工具（统计数据导出），用于用户体验改进规格 v1.4.0。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'dart:convert';

import '../../domain/entities/task_day_stats.dart';
import 'date_utils.dart';

/// CSV 导出工具。
class CsvExportUtils {
  CsvExportUtils._();

  /// 生成“按天聚合”的统计 CSV 文本。
  ///
  /// 字段：
  /// - date：YYYY-MM-DD
  /// - completed：done 数量
  /// - skipped：skipped 数量
  /// - pending：pending 数量
  /// - completion_rate：完成率百分比（0~100，保留 2 位小数；口径 done/(done+pending)）
  ///
  /// 参数：
  /// - [start] 起始日期（当天 00:00，包含）
  /// - [end] 结束日期（当天 00:00，不包含）
  /// - [statsByDay] 统计 Map（key=当天 00:00）
  ///
  /// 返回值：UTF-8 文本（不包含 BOM）。
  static String buildDailyStatisticsCsv({
    required DateTime start,
    required DateTime end,
    required Map<DateTime, TaskDayStats> statsByDay,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('date,completed,skipped,pending,completion_rate');

    final days = end.difference(start).inDays;
    for (var i = 0; i < days; i++) {
      final day = DateTime(start.year, start.month, start.day).add(
        Duration(days: i),
      );
      final stats = statsByDay[day] ?? const TaskDayStats(
        pendingCount: 0,
        doneCount: 0,
        skippedCount: 0,
      );

      final completed = stats.doneCount;
      final skipped = stats.skippedCount;
      final pending = stats.pendingCount;
      final total = completed + pending;
      final rate = total <= 0 ? 0.0 : (completed / total) * 100;

      buffer
        ..write(_csvText(YikeDateUtils.formatYmd(day)))
        ..write(',')
        ..write(completed)
        ..write(',')
        ..write(skipped)
        ..write(',')
        ..write(pending)
        ..write(',')
        ..writeln(rate.clamp(0, 100).toStringAsFixed(2));
    }

    return buffer.toString();
  }

  /// CSV 文本转义（最小化实现）。
  ///
  /// 说明：
  /// - 仅在包含逗号/双引号/换行时加引号并转义双引号
  static String _csvText(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuote) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// 将 CSV 文本编码为 UTF-8 bytes（无 BOM）。
  static List<int> toUtf8Bytes(String csvText) => utf8.encode(csvText);
}

