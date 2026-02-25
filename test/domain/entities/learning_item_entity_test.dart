// 文件用途：LearningItemEntity 单元测试（copyWith 行为）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/learning_item.dart';

void main() {
  test('copyWith 会保留未传入字段', () {
    final base = LearningItemEntity(
      id: 1,
      title: 'A',
      note: 'N',
      tags: const ['t1'],
      learningDate: DateTime(2026, 2, 25),
      createdAt: DateTime(2026, 2, 25, 10),
      updatedAt: DateTime(2026, 2, 25, 10),
    );

    final next = base.copyWith(title: 'B');
    expect(next.id, 1);
    expect(next.title, 'B');
    expect(next.note, 'N');
    expect(next.tags, const ['t1']);
  });
}

