/// 文件用途：数据模型 - 主题概览（TopicOverviewModel），用于主题列表展示聚合数据（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import '../database/database.dart';

/// 主题概览模型。
///
/// 说明：
/// - itemCount：主题下关联的学习内容条数
/// - completed/total：主题下所有复习任务的完成进度（done / (done+pending)）
class TopicOverviewModel {
  /// 构造函数。
  ///
  /// 参数：
  /// - [topic] 主题行
  /// - [itemCount] 关联内容数量
  /// - [completedCount] 已完成任务数
  /// - [totalCount] 总任务数（done+pending）
  /// 异常：无。
  const TopicOverviewModel({
    required this.topic,
    required this.itemCount,
    required this.completedCount,
    required this.totalCount,
  });

  final LearningTopic topic;
  final int itemCount;
  final int completedCount;
  final int totalCount;
}

