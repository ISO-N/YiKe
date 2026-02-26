// 文件用途：TaskDayStats 单元测试（派生字段与布尔判断）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/task_day_stats.dart';

void main() {
  test('totalCount / hasX 派生字段计算正确', () {
    final stats = TaskDayStats(pendingCount: 1, doneCount: 2, skippedCount: 3);
    expect(stats.totalCount, 6);
    expect(stats.hasPending, isTrue);
    expect(stats.hasDone, isTrue);
    expect(stats.hasSkipped, isTrue);

    final empty = TaskDayStats(pendingCount: 0, doneCount: 0, skippedCount: 0);
    expect(empty.totalCount, 0);
    expect(empty.hasPending, isFalse);
    expect(empty.hasDone, isFalse);
    expect(empty.hasSkipped, isFalse);
  });
}

