/// 文件用途：应用入口，负责初始化基础服务并启动 App。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'di/injection.dart';
import 'infrastructure/notification/background_task_service.dart';
import 'infrastructure/notification/notification_service.dart';
import 'infrastructure/widget/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化依赖注入容器（如数据库、Repository、UseCase）。
  final container = await AppInjection.createContainer();

  // 初始化通知与后台任务（v1.0 MVP：允许 ±30 分钟误差）。
  await NotificationService.instance.initialize();
  await BackgroundTaskService.initialize();

  // 初始化小组件通道（Android/iOS 小组件数据共享）。
  await WidgetService.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const YiKeApp(),
    ),
  );
}

