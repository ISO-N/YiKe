/// 文件用途：快捷键动作作用域（为不同页面提供可被全局快捷键调用的回调）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/widgets.dart';

/// 快捷键动作作用域。
///
/// 说明：
/// - DesktopShortcuts 作为全局 Shortcuts/Actions 容器，无法直接知道“当前页面的具体 FocusNode/保存逻辑”。
/// - 各页面可通过此 InheritedWidget 注册回调，实现：Ctrl/Cmd+F 聚焦搜索、Ctrl/Cmd+S 保存等。
class ShortcutActionsScope extends InheritedWidget {
  /// 构造函数。
  const ShortcutActionsScope({
    super.key,
    required super.child,
    this.onFocusSearch,
    this.onSave,
  });

  /// 请求聚焦搜索框（Ctrl/Cmd+F）。
  final VoidCallback? onFocusSearch;

  /// 保存（Ctrl/Cmd+S）。
  final VoidCallback? onSave;

  /// 从上下文获取作用域（可能为空）。
  static ShortcutActionsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShortcutActionsScope>();
  }

  @override
  bool updateShouldNotify(covariant ShortcutActionsScope oldWidget) {
    return oldWidget.onFocusSearch != onFocusSearch || oldWidget.onSave != onSave;
  }
}

