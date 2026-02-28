/// 文件用途：本地通知服务（flutter_local_notifications），用于发送复习提醒。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  /// 单例实例。
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 初始化通知服务（请求权限、初始化通道等）。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：插件初始化失败时可能抛出异常。
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Android 13+ 通知权限请求（若不可用则忽略）。
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// 查询通知是否启用（仅 Android 支持，其他平台返回 null）。
  ///
  /// 返回值：true/false/null（未知）。
  /// 异常：查询失败时可能抛出异常。
  Future<bool?> areNotificationsEnabled() async {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
  }

  /// 重新请求通知权限（Android 13+）。
  ///
  /// 返回值：是否同意（若平台不支持则返回 null）。
  Future<bool?> requestPermission() async {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// 发送复习提醒通知。
  ///
  /// 参数：
  /// - [id] 通知 ID
  /// - [title] 标题
  /// - [body] 内容
  /// 返回值：Future（无返回值）。
  /// 异常：发送失败时可能抛出异常。
  Future<void> showReviewNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'review_reminder',
      '复习提醒',
      channelDescription: '复习任务提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// 取消全部通知。
  ///
  /// 说明：用于“导入恢复后”清理旧通知残留（避免通知 ID/内容与新数据不一致）。
  /// 返回值：Future（无返回值）。
  /// 异常：取消失败时可能抛出异常。
  Future<void> cancelAll() => _plugin.cancelAll();
}
