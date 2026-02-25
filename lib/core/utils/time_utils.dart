/// 文件用途：时间字符串（HH:mm）与 TimeOfDay 互转工具。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';

class TimeUtils {
  TimeUtils._();

  /// 将 "HH:mm" 解析为 [TimeOfDay]。
  ///
  /// 参数：
  /// - [value] 时间字符串
  /// 返回值：TimeOfDay
  /// 异常：格式不合法时抛出 [FormatException]。
  static TimeOfDay parseHHmm(String value) {
    final parts = value.split(':');
    if (parts.length != 2) throw FormatException('时间格式不正确：$value');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (h < 0 || h > 23 || m < 0 || m > 59) throw FormatException('时间值越界：$value');
    return TimeOfDay(hour: h, minute: m);
  }

  /// 将 [TimeOfDay] 格式化为 "HH:mm"。
  ///
  /// 返回值：时间字符串。
  static String formatHHmm(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 判断 [now] 是否处于免打扰区间（可能跨天）。
  ///
  /// 参数：
  /// - [now] 当前时间
  /// - [start] 开始时间
  /// - [end] 结束时间
  /// 返回值：是否在免打扰区间内。
  static bool isInDoNotDisturb(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final n = now.hour * 60 + now.minute;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;

    // 不跨天：s <= e
    if (s <= e) {
      return n >= s && n <= e;
    }

    // 跨天：例如 22:00 - 08:00
    return n >= s || n <= e;
  }
}

