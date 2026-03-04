/// 文件用途：骨架屏加载态组件（延迟显示，避免 <200ms 闪烁），用于用户体验改进规格 v1.4.0。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// 骨架屏加载态包装器。
///
/// 策略：
/// - "auto"：加载 >= [delay] 才显示骨架（默认）
/// - "on"：立即显示骨架
/// - "off"：不显示骨架（保留 child 或由上层自行显示进度）
class SkeletonLoader extends StatefulWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [isLoading] 是否加载中
  /// - [strategy] 策略："auto" | "on" | "off"
  /// - [delay] auto 策略下的延迟阈值（默认 200ms）
  /// - [skeleton] 骨架内容
  /// - [child] 正常内容
  const SkeletonLoader({
    super.key,
    required this.isLoading,
    required this.strategy,
    required this.skeleton,
    required this.child,
    this.delay = const Duration(milliseconds: 200),
  });

  final bool isLoading;
  final String strategy;
  final Duration delay;
  final Widget skeleton;
  final Widget child;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> {
  Timer? _timer;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  @override
  void didUpdateWidget(covariant SkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.strategy != widget.strategy) {
      _recalc();
    }
  }

  void _recalc() {
    _timer?.cancel();
    _timer = null;

    if (!widget.isLoading) {
      setState(() => _showSkeleton = false);
      return;
    }

    switch (widget.strategy) {
      case 'off':
        setState(() => _showSkeleton = false);
        return;
      case 'on':
        setState(() => _showSkeleton = true);
        return;
      case 'auto':
      default:
        setState(() => _showSkeleton = false);
        _timer = Timer(widget.delay, () {
          if (!mounted) return;
          if (!widget.isLoading) return;
          setState(() => _showSkeleton = true);
        });
        return;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && _showSkeleton) {
      return widget.skeleton;
    }
    return widget.child;
  }
}

/// 简单 shimmer 效果（不引入第三方依赖）。
class SkeletonShimmer extends StatefulWidget {
  /// 构造函数。
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final highlight = isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.0 - 2.0 * (1 - t), 0),
              end: Alignment(1.0 + 2.0 * t, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 骨架矩形块。
class SkeletonBox extends StatelessWidget {
  /// 构造函数。
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

