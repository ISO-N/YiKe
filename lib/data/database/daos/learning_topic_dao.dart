/// 文件用途：LearningTopicDao - 学习主题数据库访问封装（Drift），用于内容关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:drift/drift.dart';

import '../../models/topic_overview_model.dart';
import '../database.dart';

/// 学习主题 DAO。
///
/// 说明：提供主题 CRUD、关联关系管理与主题概览统计查询。
class LearningTopicDao {
  /// 构造函数。
  ///
  /// 参数：
  /// - [db] 数据库实例。
  /// 异常：无。
  LearningTopicDao(this.db);

  final AppDatabase db;

  /// 插入主题。
  Future<int> insertTopic(LearningTopicsCompanion companion) {
    return db.into(db.learningTopics).insert(companion);
  }

  /// 更新主题。
  Future<bool> updateTopic(LearningTopic row) {
    return db.update(db.learningTopics).replace(row);
  }

  /// 删除主题（关联表会级联删除）。
  Future<int> deleteTopic(int id) {
    return (db.delete(db.learningTopics)..where((t) => t.id.equals(id))).go();
  }

  /// 根据 ID 获取主题。
  Future<LearningTopic?> getById(int id) {
    return (db.select(
      db.learningTopics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 获取全部主题（按创建时间倒序）。
  Future<List<LearningTopic>> getAllTopics() {
    return (db.select(
      db.learningTopics,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// 添加学习内容到主题（重复关联会被唯一索引拦截并抛出异常）。
  Future<void> addItemToTopic(int topicId, int learningItemId) async {
    await db
        .into(db.topicItemRelations)
        .insert(
          TopicItemRelationsCompanion.insert(
            topicId: topicId,
            learningItemId: learningItemId,
            createdAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// 根据 topicId + learningItemId 获取关联行（用于同步与调试）。
  Future<TopicItemRelation?> getRelationByPair(
    int topicId,
    int learningItemId,
  ) {
    return (db.select(db.topicItemRelations)
          ..where((t) => t.topicId.equals(topicId))
          ..where((t) => t.learningItemId.equals(learningItemId)))
        .getSingleOrNull();
  }

  /// 从主题中移除学习内容。
  Future<int> removeItemFromTopic(int topicId, int learningItemId) {
    return (db.delete(db.topicItemRelations)
          ..where((t) => t.topicId.equals(topicId))
          ..where((t) => t.learningItemId.equals(learningItemId)))
        .go();
  }

  /// 获取主题关联的学习内容 ID 列表。
  Future<List<int>> getItemIdsByTopicId(int topicId) async {
    final q = db.selectOnly(db.topicItemRelations)
      ..addColumns([db.topicItemRelations.learningItemId])
      ..where(db.topicItemRelations.topicId.equals(topicId))
      ..orderBy([OrderingTerm.asc(db.topicItemRelations.id)]);
    final rows = await q.get();
    return rows
        .map((r) => r.read(db.topicItemRelations.learningItemId))
        .whereType<int>()
        .toList();
  }

  /// 获取主题概览（条目数与完成进度）。
  ///
  /// 口径：
  /// - total：done + pending（skipped 不计入）
  /// - completed：done
  Future<List<TopicOverviewModel>> getTopicOverviews() async {
    final topic = db.learningTopics;
    final rel = db.topicItemRelations;
    final task = db.reviewTasks;

    // left join：允许空主题（无关联内容）也能显示。
    final query = db.select(topic).join([
      leftOuterJoin(rel, rel.topicId.equalsExp(topic.id)),
      leftOuterJoin(task, task.learningItemId.equalsExp(rel.learningItemId)),
    ]);

    final rows = await query.get();

    final map = <int, _TopicAgg>{};
    for (final row in rows) {
      final t = row.readTable(topic);
      final agg = map.putIfAbsent(t.id, () => _TopicAgg(topic: t));

      final relRow = row.readTableOrNull(rel);
      if (relRow != null) {
        agg.itemIds.add(relRow.learningItemId);
      }

      final taskRow = row.readTableOrNull(task);
      if (taskRow != null) {
        if (taskRow.status == 'done') {
          agg.completed++;
          agg.total++;
        } else if (taskRow.status == 'pending') {
          agg.total++;
        }
      }
    }

    final list = map.values
        .map(
          (e) => TopicOverviewModel(
            topic: e.topic,
            itemCount: e.itemIds.toSet().length,
            completedCount: e.completed,
            totalCount: e.total,
          ),
        )
        .toList();

    // 维持创建时间倒序（与 getAllTopics 一致）。
    list.sort((a, b) => b.topic.createdAt.compareTo(a.topic.createdAt));
    return list;
  }

  /// 检查主题名称是否已存在（忽略指定 id）。
  Future<bool> existsName(String name, {int? exceptId}) async {
    final q = db.selectOnly(db.learningTopics)
      ..addColumns([db.learningTopics.id.count()])
      ..where(db.learningTopics.name.equals(name.trim()));
    if (exceptId != null) {
      q.where(db.learningTopics.id.isNotValue(exceptId));
    }
    final row = await q.getSingle();
    final count = row.read(db.learningTopics.id.count()) ?? 0;
    return count > 0;
  }
}

class _TopicAgg {
  _TopicAgg({required this.topic});

  final LearningTopic topic;
  final List<int> itemIds = [];
  int completed = 0;
  int total = 0;
}
