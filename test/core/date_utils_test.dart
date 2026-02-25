// 文件用途：YikeDateUtils 日期工具单元测试（截断到当天、同日判断、格式化）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/date_utils.dart';

void main() {
  test('atStartOfDay 会截断到当天零点', () {
    final dt = DateTime(2026, 2, 25, 13, 45, 59);
    expect(YikeDateUtils.atStartOfDay(dt), DateTime(2026, 2, 25));
  });

  test('isSameDay 仅比较年月日', () {
    final a = DateTime(2026, 2, 25, 0, 0, 0);
    final b = DateTime(2026, 2, 25, 23, 59, 59);
    final c = DateTime(2026, 2, 26, 0, 0, 0);
    expect(YikeDateUtils.isSameDay(a, b), true);
    expect(YikeDateUtils.isSameDay(a, c), false);
  });

  test('formatYmd 输出 yyyy-MM-dd', () {
    expect(YikeDateUtils.formatYmd(DateTime(2026, 2, 5)), '2026-02-05');
  });
}
