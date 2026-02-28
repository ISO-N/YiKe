// 文件用途：单元测试 - 备份/恢复工具（规范化 JSON 与 checksum）。
// 作者：Codex
// 创建日期：2026-02-28

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/backup_utils.dart';

void main() {
  test('canonicalizeDataJson 应对 key 排序与按 uuid 排序数组元素', () async {
    final data = <String, dynamic>{
      'settings': {'b': 1, 'a': 2},
      'reviewTasks': [
        {'uuid': 'b', 'x': 1},
        {'x': 2, 'uuid': 'a'},
      ],
      'learningItems': [
        {'uuid': '2', 'title': 't'},
        {'title': 't', 'uuid': '1'},
      ],
    };

    final canonical = BackupUtils.canonicalizeDataJson(data);
    expect(
      canonical,
      '{"learningItems":[{"title":"t","uuid":"1"},{"title":"t","uuid":"2"}],'
      '"reviewTasks":[{"uuid":"a","x":2},{"uuid":"b","x":1}],'
      '"settings":{"a":2,"b":1}}',
    );

    final c1 = await BackupUtils.sha256Hex(canonical);
    final c2 = await BackupUtils.sha256Hex(canonical);
    expect(c1, startsWith('sha256:'));
    expect(c1, c2);
  });
}
