// 文件用途：艾宾浩斯复习间隔与日期计算单元测试。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/ebbinghaus_utils.dart';
import 'package:yike/domain/entities/review_config.dart';

void main() {
  test('默认复习间隔符合 v1.4 规格（扩展至 10 轮）', () {
    const expected = [1, 2, 4, 7, 15, 30, 60, 90, 120, 180];
    expect(EbbinghausUtils.defaultIntervalsDays, expected);
    expect(ReviewConfig.defaultIntervals, expected);
  });

  test('复习日期计算正确', () {
    final d0 = DateTime(2026, 2, 25);
    expect(ReviewConfig.calculateReviewDate(d0, 1), DateTime(2026, 2, 26));
    expect(ReviewConfig.calculateReviewDate(d0, 2), DateTime(2026, 2, 27));
    expect(ReviewConfig.calculateReviewDate(d0, 3), DateTime(2026, 3, 1));
    expect(ReviewConfig.calculateReviewDate(d0, 4), DateTime(2026, 3, 4));
    expect(ReviewConfig.calculateReviewDate(d0, 5), DateTime(2026, 3, 12));
    expect(ReviewConfig.calculateReviewDate(d0, 6), DateTime(2026, 3, 27));
    expect(ReviewConfig.calculateReviewDate(d0, 7), DateTime(2026, 4, 26));
    expect(ReviewConfig.calculateReviewDate(d0, 8), DateTime(2026, 5, 26));
    expect(ReviewConfig.calculateReviewDate(d0, 9), DateTime(2026, 6, 25));
    expect(ReviewConfig.calculateReviewDate(d0, 10), DateTime(2026, 8, 24));
  });
}
