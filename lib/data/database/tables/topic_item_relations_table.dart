/// 文件用途：Drift 表定义 - 主题与学习内容关联表（topic_item_relations），用于多对多关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import 'learning_items_table.dart';
import 'learning_topics_table.dart';

/// 主题-内容关联表（多对多）。
///
/// 约束：
/// - 复合唯一索引：同一主题下同一学习内容只能关联一次
/// - 删除主题时级联删除关联；删除学习内容时级联删除关联
class TopicItemRelations extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 外键：主题 ID（删除主题时级联删除）。
  IntColumn get topicId =>
      integer().references(LearningTopics, #id, onDelete: KeyAction.cascade)();

  /// 外键：学习内容 ID（删除学习内容时级联删除）。
  IntColumn get learningItemId =>
      integer().references(LearningItems, #id, onDelete: KeyAction.cascade)();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {topicId, learningItemId},
  ];
}
