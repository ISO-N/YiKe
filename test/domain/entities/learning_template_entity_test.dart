// 文件用途：LearningTemplateEntity 单元测试（copyWith 行为）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/learning_template.dart';

void main() {
  test('copyWith 会保留未传入字段并支持覆盖', () {
    final createdAt = DateTime(2026, 2, 26, 10);
    final entity = LearningTemplateEntity(
      id: 1,
      name: 'N',
      titlePattern: '{date}',
      notePattern: 'note',
      tags: const ['a'],
      sortOrder: 3,
      createdAt: createdAt,
      updatedAt: DateTime(2026, 2, 26, 11),
    );

    final next = entity.copyWith(name: 'N2', tags: const ['b', 'c']);
    expect(next.id, 1);
    expect(next.name, 'N2');
    expect(next.titlePattern, '{date}');
    expect(next.notePattern, 'note');
    expect(next.tags, ['b', 'c']);
    expect(next.sortOrder, 3);
    expect(next.createdAt, createdAt);
    expect(next.updatedAt, DateTime(2026, 2, 26, 11));
  });
}

