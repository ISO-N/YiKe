// 文件用途：FileParser 单元测试（TXT/CSV/Markdown 解析、GBK 回退、异常分支）。
// 作者：Codex
// 创建日期：2026-02-26

import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/file_parser.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yike_file_parser_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('parseFile: TXT 每行一条标题（忽略空行与首尾空白）', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}items.txt');
    await file.writeAsString('  A  \n\nB\r\n  \nC  ');

    final items = await FileParser.parseFile(file.path);
    expect(items.map((e) => e.title).toList(), ['A', 'B', 'C']);
    expect(items.every((e) => e.isValid), isTrue);
  });

  test('parseFile: CSV 支持表头、空标题报错、标签去重与多分隔符', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}items.csv');

    // 说明：第三列 tags 需要通过引号包裹，避免被 CSV 解析为多列。
    await file.writeAsString(
      '标题,备注,标签\n'
      'T1, N1 ,\"a, b，c;d；a\"\n'
      ',N2,\"x\"\n',
    );

    final items = await FileParser.parseFile(file.path);
    expect(items.length, 2);

    expect(items[0].title, 'T1');
    expect(items[0].note, 'N1');
    expect(items[0].tags.toSet(), {'a', 'b', 'c', 'd'});
    expect(items[0].isValid, isTrue);

    expect(items[1].title, '');
    expect(items[1].note, 'N2');
    expect(items[1].tags, ['x']);
    expect(items[1].errorMessage, '标题为空');
    expect(items[1].isValid, isFalse);
  });

  test('parseFile: Markdown 以标题行分段，正文合并为备注（保留空行结构）', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}items.md');
    await file.writeAsString(
      '# T1\n'
      'line1\n'
      '\n'
      'line2\n'
      '## T2\n'
      'only\n',
    );

    final items = await FileParser.parseFile(file.path);
    expect(items.length, 2);
    expect(items[0].title, 'T1');
    expect(items[0].note, 'line1\n\nline2');
    expect(items[1].title, 'T2');
    expect(items[1].note, 'only');
  });

  test('parseFile: 不支持的扩展名会抛 ArgumentError', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}items.json');
    await file.writeAsString('[]');

    expect(() => FileParser.parseFile(file.path), throwsArgumentError);
  });

  test('parseFile: UTF-8 解码失败时回退 GBK（用于历史 CSV/TXT）', () async {
    final file = File('${tempDir.path}${Platform.pathSeparator}items_gbk.txt');

    // 说明：写入“确定为 GBK 且严格 UTF-8 必定解码失败”的字节序列，确保走回退分支。
    // - “中”= D6D0（GBK），“文”= CEC4（GBK）
    final bytes = <int>[0xD6, 0xD0, 0xCE, 0xC4];
    expect(() => utf8.decode(bytes, allowMalformed: false), throwsA(anything));
    await file.writeAsBytes(bytes, flush: true);

    final items = await FileParser.parseFile(file.path);
    expect(items.length, 1);
    expect(items.single.title.trim(), isNotEmpty);
  });
}
