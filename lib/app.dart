/// 文件用途：App 根组件，提供主题与路由。
/// 作者：Codex
/// 创建日期：2026-02-25
/// 最后更新：2026-02-26（接入主题模式与深色主题）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'infrastructure/router/app_router.dart';
import 'presentation/providers/theme_provider.dart';

class YiKeApp extends ConsumerWidget {
  /// App 根组件。
  ///
  /// 返回值：返回一个使用 `MaterialApp.router` 的根组件。
  /// 异常：无。
  const YiKeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // 关键逻辑：尊重系统“减少动态效果”设置；若系统要求关闭动画则禁用主题切换动画。
    final features = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    final disableAnimations =
        features.disableAnimations || features.accessibleNavigation;
    final themeAnimationDuration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 300);
    return MaterialApp.router(
      title: '忆刻',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode.toThemeMode(),
      themeAnimationDuration: themeAnimationDuration,
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
