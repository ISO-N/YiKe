/// 文件用途：应用路由配置（GoRouter），包含底部导航与 Modal 路由。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive_utils.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/calendar/calendar_page.dart';
import '../../presentation/pages/help/help_page.dart';
import '../../presentation/pages/input/input_page.dart';
import '../../presentation/pages/input/import_preview_page.dart';
import '../../presentation/pages/input/templates_page.dart';
import '../../presentation/pages/debug/mock_data_generator_page.dart';
import '../../presentation/pages/learning_item/learning_item_detail_page.dart';
import '../../presentation/pages/settings/export_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/settings/sync_settings_page.dart';
import '../../presentation/pages/statistics/statistics_page.dart';
import '../../presentation/pages/topics/topic_detail_page.dart';
import '../../presentation/pages/topics/topics_page.dart';
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
            path: '/help',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HelpPage()),
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
          return _dialogPageIfDesktop(
            context,
            const InputPage(),
            fallback: const MaterialPage(
              fullscreenDialog: true,
              child: InputPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/input/import',
        pageBuilder: (context, state) {
          return _dialogPageIfDesktop(
            context,
            const ImportPreviewPage(),
            fallback: const MaterialPage(
              fullscreenDialog: true,
              child: ImportPreviewPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/input/templates',
        pageBuilder: (context, state) {
          return _dialogPageIfDesktop(
            context,
            const TemplatesPage(),
            fallback: const MaterialPage(
              fullscreenDialog: true,
              child: TemplatesPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/items/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const MaterialPage(child: HomePage());
          }
          return _dialogPageIfDesktop(
            context,
            LearningItemDetailPage(itemId: id),
            fallback: MaterialPage(child: LearningItemDetailPage(itemId: id)),
            dialogSize: const Size(720, 720),
          );
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
      GoRoute(
        path: '/settings/debug/mock-data',
        pageBuilder: (context, state) {
          return _dialogPageIfDesktop(
            context,
            const MockDataGeneratorPage(),
            fallback: const MaterialPage(
              fullscreenDialog: true,
              child: MockDataGeneratorPage(),
            ),
            dialogSize: const Size(680, 760),
          );
        },
      ),
      GoRoute(
        path: '/settings/sync',
        pageBuilder: (context, state) {
          return const MaterialPage(child: SyncSettingsPage());
        },
      ),
      GoRoute(
        path: '/topics',
        pageBuilder: (context, state) {
          return const MaterialPage(child: TopicsPage());
        },
      ),
      GoRoute(
        path: '/topics/:id',
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const MaterialPage(child: TopicsPage());
          }
          return MaterialPage(child: TopicDetailPage(topicId: id));
        },
      ),
    ],
  );
});

Page<dynamic> _dialogPageIfDesktop(
  BuildContext context,
  Widget child, {
  required Page<dynamic> fallback,
  Size dialogSize = const Size(600, 500),
}) {
  final isDesktop =
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  if (!isDesktop) return fallback;

  return CustomTransitionPage(
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogSize.width,
          maxHeight: dialogSize.height,
          minWidth: 360,
          minHeight: 360,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scale = Tween<double>(begin: 0.98, end: 1.0).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
