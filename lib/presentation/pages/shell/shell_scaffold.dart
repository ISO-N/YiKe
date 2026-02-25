/// 文件用途：底部导航壳层（Home/Settings），承载子路由页面。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';

class ShellScaffold extends StatelessWidget {
  /// 底部导航壳层。
  ///
  /// 参数：
  /// - [child] 当前选中 tab 对应的页面。
  /// 返回值：返回 Scaffold。
  /// 异常：无。
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/statistics')) return 2;
    if (location.startsWith('/calendar')) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        context.go('/calendar');
        return;
      case 2:
        context.go('/statistics');
        return;
      case 3:
        context.go('/settings');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    final currentIndex = _locationToIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: AppStrings.today,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: AppStrings.calendar,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: AppStrings.statistics,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}
