// 文件用途：LearningTopicOverviewEntity 单元测试（字段透传）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/learning_topic.dart';
import 'package:yike/domain/entities/learning_topic_overview.dart';

void main() {
  test('LearningTopicOverviewEntity 会保留 topic 与聚合字段', () {
    final topic = LearningTopicEntity(
      id: 1,
      name: 'T',
      createdAt: DateTime(2026, 2, 26),
    );

    final overview = LearningTopicOverviewEntity(
      topic: topic,
      itemCount: 2,
      completedCount: 3,
      totalCount: 5,
    );

    expect(overview.topic, topic);
    expect(overview.itemCount, 2);
    expect(overview.completedCount, 3);
    expect(overview.totalCount, 5);
  });
}
