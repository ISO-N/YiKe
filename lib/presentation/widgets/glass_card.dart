/// 文件用途：通用毛玻璃卡片组件（Glassmorphism），用于承载内容区块。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  /// 毛玻璃卡片。
  ///
  /// 参数：
  /// - [child] 卡片内容。
  /// - [borderRadius] 圆角。
  /// - [blurSigma] 背景模糊程度。
  /// 返回值：Widget。
  /// 异常：无。
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 14,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
