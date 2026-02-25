/// 文件用途：桌面小组件数据同步服务（home_widget），负责写入展示数据并触发刷新。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

/// 小组件展示的任务条目。
class WidgetTaskItem {
  /// 构造函数。
  ///
  /// 参数：
  /// - [title] 任务标题
  /// - [status] 状态（pending/done/skipped）
  const WidgetTaskItem({required this.title, required this.status});

  final String title;
  final String status;

  Map<String, dynamic> toJson() => {'title': title, 'status': status};
}

class WidgetService {
  static const String _widgetDataKey = 'widget_data';

  /// 初始化小组件通道。
  ///
  /// 返回值：Future（无返回值）。
  /// 异常：插件初始化失败时可能抛出异常。
  static Future<void> initialize() async {
    // v1.0 MVP：home_widget 无需显式初始化，保留扩展点。
    return;
  }

  /// 写入并刷新小组件展示数据。
  ///
  /// 参数：
  /// - [totalCount] 今日任务总数
  /// - [completedCount] 今日已完成数
  /// - [tasks] 今日任务条目（建议最多 3 条，含状态）
  /// 返回值：Future（无返回值）。
  /// 异常：写入或刷新失败时可能抛出异常。
  static Future<void> updateWidgetData({
    required int totalCount,
    required int completedCount,
    required int pendingCount,
    required List<WidgetTaskItem> tasks,
  }) async {
    // v1.0 MVP：仅要求 Android 小组件；其他平台无配置时直接忽略。
    if (!Platform.isAndroid) return;

    final widgetData = <String, dynamic>{
      'totalCount': totalCount,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'tasks': tasks.take(3).map((e) => e.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await HomeWidget.saveWidgetData(_widgetDataKey, jsonEncode(widgetData));
    await HomeWidget.updateWidget(androidName: 'YikeWidgetProvider');
  }

  /// 从小组件共享存储读取当前数据（用于调试/展示）。
  ///
  /// 返回值：JSON Map（读取失败返回 null）。
  /// 异常：无（读取异常会吞掉并返回 null）。
  static Future<Map<String, dynamic>?> getWidgetData() async {
    try {
      if (!Platform.isAndroid) return null;
      final raw = await HomeWidget.getWidgetData<String>(_widgetDataKey);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
