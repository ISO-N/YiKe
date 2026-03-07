/// 文件用途：延迟加载非关键组件（滚动到可见区域再渲染），用于性能优化（spec-user-experience-improvements.md 3.3.4）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 延迟可见构建器。
///
/// 设计目标：
/// - 首帧不构建非关键组件，降低首屏构建压力
/// - 组件滚动到可见区域后再渲染，避免“看不见但先算了”的浪费
/// - 支持最小延迟（例如首帧后 300ms），避免与首屏渲染争抢资源
class DeferredVisibilityBuilder extends StatefulWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [id] 用于 VisibilityDetector 的稳定 Key（同一个页面同一位置应保持不变）
  /// - [builder] 真正的构建逻辑（满足条件后才会执行）
  /// - [placeholder] 未满足条件时的占位（建议使用轻量布局或骨架）
  /// - [minDelay] 首帧后的最小延迟时间
  /// - [visibleFractionThreshold] 认为“可见”的阈值（0~1）
  const DeferredVisibilityBuilder({
    super.key,
    required this.id,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
    this.minDelay = const Duration(milliseconds: 300),
    this.visibleFractionThreshold = 0.12,
  });

  final String id;
  final WidgetBuilder builder;
  final Widget placeholder;
  final Duration minDelay;
  final double visibleFractionThreshold;

  @override
  State<DeferredVisibilityBuilder> createState() =>
      _DeferredVisibilityBuilderState();
}

class _DeferredVisibilityBuilderState extends State<DeferredVisibilityBuilder> {
  Timer? _delayTimer;
  bool _delayPassed = false;
  // 关键逻辑：只要“曾经可见过一次”，就允许触发构建。
  //
  // 背景：用户快速滚动可能导致“短暂可见 → 立刻不可见”，如果此时还未过 minDelay，
  // 旧实现会把 _isVisible 置回 false，从而在 delay 到期后无法构建，用户再次滚回时看到空白占位。
  bool _hasBeenVisible = false;
  bool _built = false;

  @override
  void initState() {
    super.initState();

    // 关键逻辑：延迟从“首帧之后”开始计算，避免将 build 阶段也算进来。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _delayTimer?.cancel();
      _delayTimer = Timer(widget.minDelay, () {
        if (!mounted) return;
        _delayPassed = true;
        _tryBuild();
      });
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _delayTimer = null;
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    // 只记录“可见过一次”的事实，避免快速滚动场景下反复置回不可见导致延迟构建失效。
    if (info.visibleFraction >= widget.visibleFractionThreshold) {
      _hasBeenVisible = true;
    }
    _tryBuild();
  }

  void _tryBuild() {
    if (_built) return;
    if (!_delayPassed) return;
    if (!_hasBeenVisible) return;
    setState(() => _built = true);
  }

  @override
  Widget build(BuildContext context) {
    // 关键逻辑：一旦构建完成，就不再依赖 VisibilityDetector，避免不必要的回调与潜在副作用。
    if (_built) return Builder(builder: widget.builder);

    return VisibilityDetector(
      key: ValueKey<String>('deferred_${widget.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.placeholder,
    );
  }
}
