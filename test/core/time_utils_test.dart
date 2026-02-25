// 文件用途：TimeUtils（HH:mm 解析/格式化、免打扰判断）单元测试。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/time_utils.dart';

void main() {
  test('HH:mm 解析与格式化互逆', () {
    final t = TimeUtils.parseHHmm('09:05');
    expect(t.hour, 9);
    expect(t.minute, 5);
    expect(TimeUtils.formatHHmm(t), '09:05');
  });

  test('免打扰判断：不跨天', () {
    final start = const TimeOfDay(hour: 12, minute: 0);
    final end = const TimeOfDay(hour: 13, minute: 0);
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 11, minute: 59),
        start,
        end,
      ),
      false,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 12, minute: 30),
        start,
        end,
      ),
      true,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 13, minute: 0),
        start,
        end,
      ),
      true,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 13, minute: 1),
        start,
        end,
      ),
      false,
    );
  });

  test('免打扰判断：跨天', () {
    final start = const TimeOfDay(hour: 22, minute: 0);
    final end = const TimeOfDay(hour: 8, minute: 0);
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 21, minute: 59),
        start,
        end,
      ),
      false,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 22, minute: 0),
        start,
        end,
      ),
      true,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 2, minute: 0),
        start,
        end,
      ),
      true,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 8, minute: 0),
        start,
        end,
      ),
      true,
    );
    expect(
      TimeUtils.isInDoNotDisturb(
        const TimeOfDay(hour: 8, minute: 1),
        start,
        end,
      ),
      false,
    );
  });
}
