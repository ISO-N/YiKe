/// 文件用途：桌面小组件数据同步服务（home_widget），负责写入展示数据并触发刷新。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';

import 'package:home_widget/home_widget.dart';

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
  /// - [titles] 今日任务标题列表（建议最多 3 条）
  /// 返回值：Future（无返回值）。
  /// 异常：写入或刷新失败时可能抛出异常。
  static Future<void> updateWidgetData({
    required int totalCount,
    required int completedCount,
    required List<String> titles,
  }) async {
    final widgetData = <String, dynamic>{
      'totalCount': totalCount,
      'completedCount': completedCount,
      'tasks': titles.take(3).toList(),
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
      final raw = await HomeWidget.getWidgetData<String>(_widgetDataKey);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
