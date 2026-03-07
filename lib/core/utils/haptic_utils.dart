/// 文件用途：触觉反馈工具（统一封装 light/medium/heavy），用于用户体验改进规格 v1.4.0。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 触觉反馈工具。
class HapticUtils {
  HapticUtils._();

  /// 轻触觉反馈（用于按钮点击/任务完成等）。
  ///
  /// 参数：
  /// - [context] 用于读取系统“减少动态效果”设置
  /// - [enabledByUser] 用户开关（UI 偏好）
  /// - [ignoreReduceMotion] 是否忽略“减少动态效果”（如目标达成等重要反馈）
  static Future<void> lightImpact(
    BuildContext context, {
    required bool enabledByUser,
    bool ignoreReduceMotion = false,
  }) async {
    if (!_canHaptic(context, enabledByUser, ignoreReduceMotion)) return;
    await HapticFeedback.lightImpact();
  }

  /// 中触觉反馈（用于下拉刷新触发等）。
  static Future<void> mediumImpact(
    BuildContext context, {
    required bool enabledByUser,
    bool ignoreReduceMotion = false,
  }) async {
    if (!_canHaptic(context, enabledByUser, ignoreReduceMotion)) return;
    await HapticFeedback.mediumImpact();
  }

  /// 重触觉反馈（用于目标达成等“重要成就”）。
  static Future<void> heavyImpact(
    BuildContext context, {
    required bool enabledByUser,
    bool ignoreReduceMotion = true,
  }) async {
    if (!_canHaptic(context, enabledByUser, ignoreReduceMotion)) return;
    await HapticFeedback.heavyImpact();
  }

  static bool _canHaptic(
    BuildContext context,
    bool enabledByUser,
    bool ignoreReduceMotion,
  ) {
    if (!enabledByUser) return false;

    // 桌面端禁用（规格要求）。
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return false;
    }

    if (ignoreReduceMotion) return true;

    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return true;
    return !(mq.disableAnimations || mq.accessibleNavigation);
  }
}
