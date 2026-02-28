/// 文件用途：数据模型 - 任务时间线查询结果（包含发生时间 occurredAt）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'review_task_with_item_model.dart';

/// 任务时间线数据模型。
///
/// 说明：
/// - [model] 为“任务 + 学习内容”联合结果
/// - [occurredAt] 为发生时间（pending 用 scheduledDate，done 用 completedAt，skipped 用 skippedAt；空值回退 scheduledDate）
class ReviewTaskTimelineModel {
  /// 构造函数。
  const ReviewTaskTimelineModel({required this.model, required this.occurredAt});

  final ReviewTaskWithItemModel model;
  final DateTime occurredAt;
}

