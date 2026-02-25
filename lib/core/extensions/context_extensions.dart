/// 文件用途：BuildContext 扩展，简化常用访问（Theme/ColorScheme 等）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  /// 快捷获取 `ThemeData`。
  ThemeData get theme => Theme.of(this);

  /// 快捷获取 `ColorScheme`。
  ColorScheme get colors => theme.colorScheme;

  /// 快捷获取屏幕尺寸。
  Size get screenSize => MediaQuery.sizeOf(this);
}

