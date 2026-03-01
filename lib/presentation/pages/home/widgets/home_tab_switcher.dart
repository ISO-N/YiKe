/// 文件用途：首页“今日/全部”二级切换组件（SegmentedButton）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';

/// 首页任务范围 Tab。
enum HomeTaskTab {
  /// 今日（默认）。
  today,

  /// 全部任务（复用任务中心逻辑）。
  all,
}

/// HomeTaskTab 扩展：用于路由参数解析与展示文案。
extension HomeTaskTabX on HomeTaskTab {
  /// 将路由 query 参数解析为 Tab；未知值默认回退到 today。
  static HomeTaskTab fromQuery(String? value) {
    return switch (value) {
      'all' => HomeTaskTab.all,
      _ => HomeTaskTab.today,
    };
  }

  /// 用于写回路由的 query 值；today 允许省略（保持 `/home` 为默认）。
  String get queryValue => switch (this) {
    HomeTaskTab.today => 'today',
    HomeTaskTab.all => 'all',
  };

  /// UI 文案。
  String get label => switch (this) {
    HomeTaskTab.today => '今日',
    HomeTaskTab.all => '全部',
  };
}

/// 首页二级切换器。
///
/// 说明：
/// - 使用 Material 3 SegmentedButton，符合平台默认交互与动画规范。
/// - 仅承担“范围切换”职责，具体数据/筛选逻辑由上层页面负责。
class HomeTabSwitcher extends StatelessWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [tab] 当前选中 Tab。
  /// - [onChanged] 选中变化回调。
  /// 返回值：Widget。
  /// 异常：无。
  const HomeTabSwitcher({
    super.key,
    required this.tab,
    required this.onChanged,
  });

  final HomeTaskTab tab;
  final ValueChanged<HomeTaskTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '首页任务范围切换',
      child: SegmentedButton<HomeTaskTab>(
        segments: const [
          ButtonSegment<HomeTaskTab>(
            value: HomeTaskTab.today,
            label: Text('今日'),
          ),
          ButtonSegment<HomeTaskTab>(
            value: HomeTaskTab.all,
            label: Text('全部'),
          ),
        ],
        selected: {tab},
        onSelectionChanged: (selection) {
          final next = selection.isEmpty ? tab : selection.first;
          if (next == tab) return;
          onChanged(next);
        },
      ),
    );
  }
}

