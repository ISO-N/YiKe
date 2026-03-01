/// 文件用途：Shell 层统一悬浮按钮（FAB），用于触发“录入”入口。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';

/// Shell 层统一 FAB。
///
/// 设计说明：
/// - 入口统一：录入功能只保留一个入口（符合 UI 布局精简规范）。
/// - 路由保持：点击后始终跳转 `/input`，桌面端/移动端具体呈现由路由层策略决定。
class ShellFAB extends StatelessWidget {
  /// 构造函数。
  ///
  /// 返回值：Widget。
  /// 异常：无。
  const ShellFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.input,
      child: FloatingActionButton.extended(
        tooltip: AppStrings.input,
        onPressed: () => context.push('/input'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.input),
      ),
    );
  }
}

