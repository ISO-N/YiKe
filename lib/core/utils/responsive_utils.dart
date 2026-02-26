/// 文件用途：响应式布局工具（F11）——统一断点与列数计算，服务移动端/桌面端适配。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';

/// 响应式断点常量。
///
/// 说明（与 UI/UX v3.0 对齐）：
/// - < 600：手机
/// - 600-899：大屏手机/小平板
/// - 900-1199：平板/小桌面
/// - ≥ 1200：桌面
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// 响应式工具方法集合。
class ResponsiveUtils {
  ResponsiveUtils._();

  /// 是否为手机宽度。
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  /// 是否为平板宽度。
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.tablet;
  }

  /// 是否为桌面宽度。
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  /// 获取任务列表建议列数。
  ///
  /// 说明：
  /// - ≥1200：2 列（PRD 验收口径：双列）
  /// - ≥900：2 列
  /// - 其他：1 列
  static int getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.desktop) return 2;
    if (width >= ResponsiveBreakpoints.tablet) return 2;
    return 1;
  }
}
