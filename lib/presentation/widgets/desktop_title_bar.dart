/// 文件用途：桌面端自定义标题栏（F11）——支持拖动、最小化到托盘、最大化/还原、关闭。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../infrastructure/desktop/tray_service.dart';

/// 桌面端窗口框架：在页面内容上方插入自定义标题栏。
class DesktopWindowFrame extends StatelessWidget {
  const DesktopWindowFrame({
    super.key,
    required this.child,
    this.title,
    this.actions,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopTitleBar(title: title ?? AppStrings.appName, actions: actions),
        Expanded(child: child),
      ],
    );
  }
}

/// 桌面端自定义标题栏。
class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withAlpha(80),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.school,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (actions != null) ...actions!,
            const SizedBox(width: AppSpacing.sm),
            const _WindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowButton(
          tooltip: '最小化到托盘',
          icon: Icons.remove,
          onPressed: () => TrayService.instance.minimizeToTray(),
          hoverColor: Colors.grey.withAlpha(30),
        ),
        _WindowButton(
          tooltip: '最大化/还原',
          icon: Icons.crop_square,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          hoverColor: Colors.grey.withAlpha(30),
        ),
        _WindowButton(
          tooltip: '关闭',
          icon: Icons.close,
          onPressed: () => windowManager.close(),
          hoverColor: Colors.red.withAlpha(200),
          hoverIconColor: Colors.white,
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.hoverIconColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final Color? hoverIconColor;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = _isHovering
        ? (widget.hoverIconColor ??
              Theme.of(context).colorScheme.onSurface.withAlpha(230))
        : Theme.of(context).colorScheme.onSurface.withAlpha(160);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: 32,
            decoration: BoxDecoration(
              color: _isHovering ? widget.hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}
