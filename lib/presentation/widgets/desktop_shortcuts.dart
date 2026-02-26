/// 文件用途：桌面端快捷键支持（F11）——为常用操作提供键盘入口（Ctrl+N/Ctrl+R/Ctrl+,/Ctrl+H/Esc）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calendar_provider.dart';
import '../providers/home_tasks_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';

/// 桌面端快捷键包装器。
///
/// 说明：
/// - 仅在桌面端启用（由上层按平台/尺寸判断后决定是否包裹）
/// - 快捷键语义遵循 PRD v3.0 / UI-UX v3.0
class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const _NewItemIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            const _RefreshIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma):
            const _OpenSettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH):
            const _OpenHelpIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewItemIntent: CallbackAction<_NewItemIntent>(
            onInvoke: (_) {
              context.push('/input');
              return null;
            },
          ),
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (_) {
              _refreshByRoute(context);
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              context.go('/settings');
              return null;
            },
          ),
          _OpenHelpIntent: CallbackAction<_OpenHelpIntent>(
            onInvoke: (_) {
              context.go('/help');
              return null;
            },
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  void _refreshByRoute(BuildContext context) {
    // 关键逻辑：按当前路由前缀选择刷新目标，避免全局无差别刷新导致重复请求。
    final container = ProviderScope.containerOf(context);
    final location = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.toString();

    if (location.startsWith('/home')) {
      container.invalidate(homeTasksProvider);
      return;
    }
    if (location.startsWith('/calendar')) {
      container.invalidate(calendarProvider);
      return;
    }
    if (location.startsWith('/statistics')) {
      container.invalidate(statisticsProvider);
      return;
    }
    if (location.startsWith('/settings')) {
      container.invalidate(settingsProvider);
      return;
    }
  }
}

class _NewItemIntent extends Intent {
  const _NewItemIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _OpenHelpIntent extends Intent {
  const _OpenHelpIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}
