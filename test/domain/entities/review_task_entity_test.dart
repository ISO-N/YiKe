// 文件用途：ReviewTaskEntity/ReviewTaskStatus 单元测试（状态映射与 copyWith）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/review_task.dart';

void main() {
  test('ReviewTaskStatusX toDbValue 映射正确', () {
    expect(ReviewTaskStatus.pending.toDbValue(), 'pending');
    expect(ReviewTaskStatus.done.toDbValue(), 'done');
    expect(ReviewTaskStatus.skipped.toDbValue(), 'skipped');
  });

  test('ReviewTaskStatusX fromDbValue 对未知值回退 pending', () {
    expect(ReviewTaskStatusX.fromDbValue('pending'), ReviewTaskStatus.pending);
    expect(ReviewTaskStatusX.fromDbValue('done'), ReviewTaskStatus.done);
    expect(ReviewTaskStatusX.fromDbValue('skipped'), ReviewTaskStatus.skipped);
    expect(ReviewTaskStatusX.fromDbValue('unknown'), ReviewTaskStatus.pending);
  });

  test('ReviewTaskEntity copyWith 会保留未传入字段', () {
    final base = ReviewTaskEntity(
      id: 1,
      learningItemId: 2,
      reviewRound: 1,
      scheduledDate: DateTime(2026, 2, 26),
      status: ReviewTaskStatus.pending,
      completedAt: null,
      skippedAt: null,
      createdAt: DateTime(2026, 2, 25, 9),
    );

    final next = base.copyWith(status: ReviewTaskStatus.done, completedAt: DateTime(2026, 2, 26));
    expect(next.id, 1);
    expect(next.learningItemId, 2);
    expect(next.status, ReviewTaskStatus.done);
    expect(next.completedAt, DateTime(2026, 2, 26));
  });
}

