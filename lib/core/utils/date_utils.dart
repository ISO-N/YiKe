/// 文件用途：日期相关工具函数（截断到日期、格式化等）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:intl/intl.dart';

class YikeDateUtils {
  YikeDateUtils._();

  /// 将时间截断到当天 00:00:00（用于按“日期”查询）。
  ///
  /// 参数：
  /// - [dateTime] 原始时间。
  /// 返回值：当天零点时间。
  /// 异常：无。
  static DateTime atStartOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// 判断两个时间是否为同一天（按年月日）。
  ///
  /// 参数：
  /// - [a] 时间 A
  /// - [b] 时间 B
  /// 返回值：是否同一天。
  /// 异常：无。
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 格式化日期用于展示（如 2026-02-25）。
  ///
  /// 参数：
  /// - [date] 日期
  /// 返回值：格式化字符串。
  /// 异常：无。
  static String formatYmd(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

