/// 文件用途：应用入口，负责初始化基础服务并启动 App。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'di/injection.dart';
import 'di/providers.dart';
import 'infrastructure/desktop/tray_service.dart';
import 'infrastructure/notification/background_task_service.dart';
import 'infrastructure/notification/notification_service.dart';
import 'infrastructure/storage/backup_storage.dart';
import 'infrastructure/widget/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // v3.0（F11）：桌面端窗口与托盘初始化。
  await _initDesktopIfNeeded();

  // 初始化依赖注入容器（如数据库、Repository、UseCase）。
  final container = await AppInjection.createContainer();

  // v2.6：任务结构迁移（note → description + subtasks）。
  //
  // 说明：
  // - 必须在 UI 首次读取学习内容/任务之前执行，避免 note/description 显示闪烁
  // - 迁移幂等：成功后会将 note 置空
  await container.read(migrateNoteToSubtasksUseCaseProvider).execute();

  // 初始化通知与后台任务（v1.0 MVP：允许 ±30 分钟误差）。
  await NotificationService.instance.initialize();
  await BackgroundTaskService.initialize();

  // v1.5：备份恢复 - 清理上次中断遗留的临时文件（*.tmp），避免备份历史出现半成品。
  await const BackupStorage().cleanupTempFiles();

  // 初始化小组件通道（Android/iOS 小组件数据共享）。
  await WidgetService.initialize();

  runApp(
    UncontrolledProviderScope(container: container, child: const YiKeApp()),
  );
}

Future<void> _initDesktopIfNeeded() async {
  if (kIsWeb) return;
  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (!isDesktop) return;

  await windowManager.ensureInitialized();

  final options = WindowOptions(
    size: const Size(1200, 800),
    minimumSize: const Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: Platform.isWindows ? TitleBarStyle.hidden : null,
    title: '忆刻',
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化托盘（仅桌面端）。
  await TrayService.instance.init();
}
