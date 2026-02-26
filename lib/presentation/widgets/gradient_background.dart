/// 文件用途：页面渐变背景组件，支持深色模式动态适配。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// 渐变背景容器。
///
/// 说明：
/// - 浅色模式沿用 v2.0 的柔和渐变
/// - 深色模式使用低饱和度渐变（OLED Optimized）
class GradientBackground extends StatelessWidget {
  /// 构造函数。
  const GradientBackground({super.key, required this.child});

  /// 子组件。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkBackground,
                  AppColors.darkSurface,
                  AppColors.darkBackground,
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE6FFFB),
                  AppColors.background,
                  Color(0xFFFFF7ED),
                ],
              ),
      ),
      child: child,
    );
  }
}

