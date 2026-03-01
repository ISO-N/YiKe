/// 文件用途：任务完成“缩放+淡出”移除动画组件（v1.1.0 体验增强）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';

/// 任务完成移除动画。
///
/// 交互口径：
/// - 仅用于按钮/菜单触发的“完成”操作（左滑 Dismissible 使用系统自带滑出）
/// - 采用“操作先行”：上层应在数据库操作成功并刷新列表后，再触发本动画
/// - 系统开启「减少动态效果」时，上层应直接跳过动画（将 [enabled] 置为 false）
class CompletionAnimation extends StatefulWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [child] 被动画包裹的任务卡片。
  /// - [play] 是否播放动画（由上层控制）。
  /// - [enabled] 是否允许动画（无障碍“减少动效”时传 false）。
  /// - [onCompleted] 动画结束回调（用于上层移除占位卡片）。
  const CompletionAnimation({
    super.key,
    required this.child,
    required this.play,
    required this.enabled,
    this.onCompleted,
  });

  final Widget child;
  final bool play;
  final bool enabled;
  final VoidCallback? onCompleted;

  @override
  State<CompletionAnimation> createState() => _CompletionAnimationState();
}

class _CompletionAnimationState extends State<CompletionAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  bool _completedCallbackFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (_completedCallbackFired) return;
      _completedCallbackFired = true;
      widget.onCompleted?.call();
    });

    _tryPlay();
  }

  @override
  void didUpdateWidget(covariant CompletionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.play != widget.play || oldWidget.enabled != widget.enabled) {
      _tryPlay();
    }
  }

  void _tryPlay() {
    if (!widget.play) return;
    if (!widget.enabled) {
      // 无障碍降级：不播放动画，直接通知上层移除。
      if (_completedCallbackFired) return;
      _completedCallbackFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onCompleted?.call();
      });
      return;
    }

    if (_controller.isAnimating || _controller.isCompleted) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 透明度：1.0 → 0.0（淡出）
    // 缩放：1.0 → 1.15（轻微放大后消失）
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_opacity),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
