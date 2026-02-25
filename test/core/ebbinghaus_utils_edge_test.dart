// 文件用途：EbbinghausUtils 边界条件单元测试（round 越界抛 RangeError）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/ebbinghaus_utils.dart';

void main() {
  test('calculateReviewDate: round 越界会抛 RangeError', () {
    final d0 = DateTime(2026, 2, 25);
    expect(() => EbbinghausUtils.calculateReviewDate(d0, 0), throwsRangeError);
    expect(() => EbbinghausUtils.calculateReviewDate(d0, 999), throwsRangeError);
  });
}

