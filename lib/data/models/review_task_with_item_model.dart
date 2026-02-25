/// 文件用途：数据模型 - 复习任务与学习内容的联合结果（用于展示层）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../database/database.dart';

/// 复习任务 + 学习内容联合模型。
///
/// 说明：Home 页需要展示任务标题，因此 DAO 提供 join 结果。
class ReviewTaskWithItemModel {
  /// 构造函数。
  ///
  /// 参数：
  /// - [task] 复习任务行
  /// - [item] 学习内容行
  /// 异常：无。
  const ReviewTaskWithItemModel({
    required this.task,
    required this.item,
  });

  final ReviewTask task;
  final LearningItem item;
}

