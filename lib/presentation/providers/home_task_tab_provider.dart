/// 文件用途：首页 Tab 状态 Provider（替代 URL query 参数，避免路由重建触发全量页面刷新）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/home/widgets/home_tab_switcher.dart';

/// 首页任务范围 Tab Provider。
///
/// 背景：原实现使用 URL query 参数控制 Tab，切换时触发路由变化导致整个页面重建。
/// 优化：使用 StateProvider 管理本地状态，避免不必要的路由重建和全量页面刷新。
final homeTaskTabProvider = StateProvider<HomeTaskTab>(
  (ref) => HomeTaskTab.today,
);
