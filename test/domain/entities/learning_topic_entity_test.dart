// 文件用途：LearningTopicEntity 单元测试（copyWith 与 itemIds）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/learning_topic.dart';

import '../../helpers/test_uuid.dart';

void main() {
  test('copyWith 会保留未传入字段并可覆盖 itemIds', () {
    final createdAt = DateTime(2026, 2, 26, 10);
    final entity = LearningTopicEntity(
      id: 10,
      uuid: testUuid(1),
      name: 'Topic',
      description: 'desc',
      createdAt: createdAt,
      updatedAt: DateTime(2026, 2, 26, 11),
      itemIds: const [1, 2],
    );

    final next = entity.copyWith(name: 'Topic2', itemIds: const [3]);
    expect(next.id, 10);
    expect(next.name, 'Topic2');
    expect(next.description, 'desc');
    expect(next.createdAt, createdAt);
    expect(next.updatedAt, DateTime(2026, 2, 26, 11));
    expect(next.itemIds, [3]);
  });
}
