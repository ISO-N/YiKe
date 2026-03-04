/// 文件用途：颜色工具函数（HEX 字符串与 Color 转换），用于主题自定义等场景。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/material.dart';

/// 颜色工具类。
class ColorUtils {
  ColorUtils._();

  /// 将 HEX 字符串解析为 [Color]。
  ///
  /// 支持格式：
  /// - "#RRGGBB"
  /// - "RRGGBB"
  /// - "#AARRGGBB"
  /// - "AARRGGBB"
  ///
  /// 参数：
  /// - [hex] HEX 字符串
  /// 返回值：解析成功返回 [Color]，失败返回 null。
  static Color? tryParseHex(String? hex) {
    final raw = hex?.trim();
    if (raw == null || raw.isEmpty) return null;

    var s = raw.startsWith('#') ? raw.substring(1) : raw;
    if (s.length == 6) {
      // 默认不透明。
      s = 'FF$s';
    }
    if (s.length != 8) return null;

    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  /// 将 [Color] 转为规范化 HEX（#RRGGBB）。
  ///
  /// 说明：为与设置项 key 的默认值保持一致，这里默认不输出 alpha。
  static String toHexRgb(Color color) {
    // Flutter 3.41+：Color.red/green/blue 已废弃，推荐使用 0~1 的 r/g/b 分量。
    int c(double v) => (v * 255.0).round().clamp(0, 255);

    final r = c(color.r).toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = c(color.g).toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = c(color.b).toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }
}
