/// 文件用途：领域实体 - 主题概览（LearningTopicOverviewEntity），用于主题列表聚合展示（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'learning_topic.dart';

/// 主题概览实体。
///
/// 说明：
/// - itemCount：主题下关联的学习内容条数
/// - completed/total：主题下所有复习任务的完成进度（done / (done+pending)，skipped 不计入）
class LearningTopicOverviewEntity {
  /// 构造函数。
  const LearningTopicOverviewEntity({
    required this.topic,
    required this.itemCount,
    required this.completedCount,
    required this.totalCount,
  });

  final LearningTopicEntity topic;
  final int itemCount;
  final int completedCount;
  final int totalCount;
}

