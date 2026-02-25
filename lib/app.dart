/// 文件用途：App 根组件，提供主题与路由。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'infrastructure/router/app_router.dart';

class YiKeApp extends ConsumerWidget {
  /// App 根组件。
  ///
  /// 返回值：返回一个使用 `MaterialApp.router` 的根组件。
  /// 异常：无。
  const YiKeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '忆刻',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

