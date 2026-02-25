/// 文件用途：通知权限状态 Provider（用于首页弹窗引导与设置页权限状态展示）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/notification/notification_service.dart';

/// 通知权限状态。
enum NotificationPermissionState {
  /// 平台不支持/无法判断（如 Web、桌面、或插件不支持）。
  unknown,

  /// 已开启。
  enabled,

  /// 已关闭（系统层面禁用通知）。
  disabled,
}

/// 通知权限状态 Provider（异步）。
final notificationPermissionProvider =
    FutureProvider<NotificationPermissionState>((ref) async {
      // v1.0 MVP：核心目标是 Android；其他平台无法准确判断时返回 unknown。
      if (!Platform.isAndroid) return NotificationPermissionState.unknown;

      final enabled = await NotificationService.instance
          .areNotificationsEnabled();
      if (enabled == null) return NotificationPermissionState.unknown;
      return enabled
          ? NotificationPermissionState.enabled
          : NotificationPermissionState.disabled;
    });
