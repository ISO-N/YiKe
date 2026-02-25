/// 文件用途：应用路由配置（GoRouter），包含底部导航与 Modal 路由。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/calendar/calendar_page.dart';
import '../../presentation/pages/input/input_page.dart';
import '../../presentation/pages/settings/export_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/statistics/statistics_page.dart';
import '../../presentation/pages/shell/shell_scaffold.dart';

/// App 路由 Provider。
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarPage()),
          ),
          GoRoute(
            path: '/statistics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatisticsPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/input',
        pageBuilder: (context, state) {
          return const MaterialPage(fullscreenDialog: true, child: InputPage());
        },
      ),
      GoRoute(
        path: '/settings/export',
        pageBuilder: (context, state) {
          return const MaterialPage(
            fullscreenDialog: true,
            child: ExportPage(),
          );
        },
      ),
    ],
  );
});
