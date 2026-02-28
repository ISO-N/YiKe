/// 文件用途：首页任务状态筛选 Provider（独立于日历筛选，符合“今日视角”语义）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_filter_provider.dart';

/// 首页筛选条件 Provider（单选）。
///
/// 默认值：待复习（保持现有首页行为不变）。
final homeTaskFilterProvider = StateProvider<ReviewTaskFilter>(
  (ref) => ReviewTaskFilter.pending,
);

