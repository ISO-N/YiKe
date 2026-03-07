/// 文件用途：统一下拉刷新指示器样式与触觉反馈（spec-user-experience-improvements.md 3.2.4）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/material.dart';

import '../../core/utils/haptic_utils.dart';

/// 忆刻下拉刷新包装器。
///
/// 目标：
/// - 样式：刷新圆环颜色与主题主色对齐
/// - 触觉：触发刷新时提供 mediumImpact（受“减少动态效果”与用户开关影响）
///
/// 说明：
/// - 该组件仅用于“下拉触发”的刷新；按钮点击刷新应使用 lightImpact（避免误触觉等级）。
class YiKeRefreshIndicator extends StatelessWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [onRefresh] 下拉触发刷新回调
  /// - [child] 可滚动内容
  /// - [hapticEnabledByUser] 用户触觉反馈开关（UI 偏好）
  const YiKeRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    required this.hapticEnabledByUser,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool hapticEnabledByUser;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      // 规格要求：刷新圆环颜色与主题主色对齐。
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        // 规格要求：下拉刷新触发中触觉反馈（桌面端会被工具类禁用）。
        await HapticUtils.mediumImpact(
          context,
          enabledByUser: hapticEnabledByUser,
        );
        await onRefresh();
      },
      child: child,
    );
  }
}
