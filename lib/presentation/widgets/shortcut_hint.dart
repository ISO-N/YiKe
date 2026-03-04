/// 文件用途：桌面端快捷键提示 UI（spec-user-experience-improvements.md 3.4.3）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 快捷键提示作用域。
///
/// 说明：
/// - 仅用于控制“是否展示快捷键提示 UI”，不影响 Shortcuts/Actions 本身
/// - 默认规则：仅 Windows 桌面端展示（符合规格）
class ShortcutHintScope extends InheritedWidget {
  /// 构造函数。
  const ShortcutHintScope({
    super.key,
    required this.shouldShowHints,
    required super.child,
  });

  /// 是否允许展示快捷键提示。
  ///
  /// 规格约束（3.4.3）：
  /// - 仅 Windows 桌面端显示
  /// - 仅外接实体键盘时显示（桌面端默认视为有实体键盘）
  final bool shouldShowHints;

  /// 读取作用域。
  static ShortcutHintScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShortcutHintScope>();
  }

  @override
  bool updateShouldNotify(covariant ShortcutHintScope oldWidget) {
    return oldWidget.shouldShowHints != shouldShowHints;
  }
}

/// 快捷键提示胶囊（小标签）。
class ShortcutHintPill extends StatelessWidget {
  /// 构造函数。
  const ShortcutHintPill({
    super.key,
    required this.hint,
  });

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        hint,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 带快捷键提示的 IconButton（桌面端鼠标悬停时显示）。
class ShortcutHintIconButton extends StatefulWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [hint] 例如 `Ctrl+R` / `Ctrl+N`
  /// - [tooltip] 按钮 Tooltip（会自动拼接 hint）
  /// - [icon] 按钮图标
  /// - [onPressed] 点击回调
  const ShortcutHintIconButton({
    super.key,
    required this.hint,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String hint;
  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  State<ShortcutHintIconButton> createState() => _ShortcutHintIconButtonState();
}

class _ShortcutHintIconButtonState extends State<ShortcutHintIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scope = ShortcutHintScope.maybeOf(context);
    final showHints = scope?.shouldShowHints ?? false;

    // 触屏设备不展示 hover UI；同时遵循“仅 Windows 桌面端显示”的规格。
    final canHover = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    final tooltip = showHints ? '${widget.tooltip}（${widget.hint}）' : widget.tooltip;
    final showPill = showHints && canHover && _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        // 无障碍朗读需要包含快捷键信息（规格要求）。
        label: tooltip,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: tooltip,
              onPressed: widget.onPressed,
              icon: widget.icon,
            ),
            if (showPill)
              Positioned(
                right: -6,
                top: 38,
                child: ShortcutHintPill(hint: widget.hint),
              ),
          ],
        ),
      ),
    );
  }
}

