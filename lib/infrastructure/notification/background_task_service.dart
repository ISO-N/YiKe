/// 文件用途：后台任务调度（Workmanager），用于定期检查并发送通知（允许 ±30 分钟误差）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

/// 后台任务服务。
///
/// 说明：v1.0 MVP 采用“每小时检查一次”的方式，在接近提醒时间时发送通知。
class BackgroundTaskService {
  static const String _dailyReviewCheckTaskName = 'dailyReviewCheck';
  static const String _dailyReviewCheckUniqueName = 'daily_review_check';

  /// 初始化后台任务系统。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：注册失败时可能抛出异常。
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // 每小时检查一次（在提醒时间附近触发通知）。
    await Workmanager().registerPeriodicTask(
      _dailyReviewCheckUniqueName,
      _dailyReviewCheckTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
}

/// WorkManager 回调入口。
///
/// 说明：必须为顶层函数，且标记 entry-point，避免 AOT 裁剪。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    switch (task) {
      case BackgroundTaskService._dailyReviewCheckTaskName:
        // TODO: v1.0 MVP：实现“读取设置 -> 查询今日任务 -> 检查免打扰 -> 发送通知”。
        break;
    }

    return Future.value(true);
  });
}
