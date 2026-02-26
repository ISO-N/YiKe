// 文件用途：ReviewIntervalConfigEntity 单元测试（参数校验与 copyWith）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/review_interval_config.dart';

void main() {
  test('构造函数会校验 round 与 intervalDays 边界', () {
    expect(
      () => ReviewIntervalConfigEntity(round: 0, intervalDays: 1, enabled: true),
      throwsArgumentError,
    );
    expect(
      () => ReviewIntervalConfigEntity(round: 6, intervalDays: 1, enabled: true),
      throwsArgumentError,
    );
    expect(
      () => ReviewIntervalConfigEntity(round: 1, intervalDays: 0, enabled: true),
      throwsArgumentError,
    );

    final ok = ReviewIntervalConfigEntity(
      round: 1,
      intervalDays: 2,
      enabled: false,
    );
    expect(ok.round, 1);
    expect(ok.intervalDays, 2);
    expect(ok.enabled, isFalse);
  });

  test('copyWith 会创建新实例并应用覆盖字段', () {
    final base = ReviewIntervalConfigEntity(
      round: 2,
      intervalDays: 4,
      enabled: true,
    );
    final next = base.copyWith(intervalDays: 5, enabled: false);
    expect(next.round, 2);
    expect(next.intervalDays, 5);
    expect(next.enabled, isFalse);
  });
}

