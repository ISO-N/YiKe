/// 文件用途：工具类 - 文件解析器（FileParser），用于批量导入（F1.1）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:gbk_codec/gbk_codec.dart';

/// 解析后的条目（用于导入预览）。
class ParsedItem {
  /// 构造函数。
  const ParsedItem({
    required this.title,
    this.note,
    this.tags = const [],
    this.errorMessage,
  });

  /// 标题（必填）。
  final String title;

  /// 备注（可选）。
  final String? note;

  /// 标签（可选）。
  final List<String> tags;

  /// 行级错误（可选）：用于预览页标红提示。
  final String? errorMessage;

  bool get isValid => errorMessage == null && title.trim().isNotEmpty;

  ParsedItem copyWith({
    String? title,
    String? note,
    List<String>? tags,
    String? errorMessage,
  }) {
    return ParsedItem(
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      errorMessage: errorMessage,
    );
  }
}

/// 文件解析器。
class FileParser {
  FileParser._();

  /// 从本地文件解析学习内容条目。
  ///
  /// 支持：
  /// - TXT：每行一条标题
  /// - CSV：标题,备注,标签（可包含表头行）
  /// - Markdown：以 `#` 开头的标题作为条目标题，后续内容合并为备注
  ///
  /// 异常：文件读取或解析失败时可能抛出异常。
  static Future<List<ParsedItem>> parseFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final ext = _lowerExt(filePath);

    if (ext == '.txt') {
      final content = _decodeUtf8OrGbk(bytes);
      return _parseTxt(content);
    }
    if (ext == '.csv') {
      final content = _decodeUtf8OrGbk(bytes);
      return _parseCsv(content);
    }
    if (ext == '.md' || ext == '.markdown') {
      final content = _decodeUtf8OrGbk(bytes);
      return _parseMarkdown(content);
    }

    throw ArgumentError('不支持的文件格式：$ext');
  }

  static String _lowerExt(String filePath) {
    final idx = filePath.lastIndexOf('.');
    if (idx < 0) return '';
    return filePath.substring(idx).toLowerCase();
  }

  /// CSV 支持 GBK/UTF-8 自动识别：优先 UTF-8，失败则回退 GBK。
  static String _decodeUtf8OrGbk(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      // 关键逻辑：GBK/GB2312 在部分历史 CSV 中常见，这里做兜底解码。
      // 保护：若第三方 GBK 解码在特定环境不可用/异常，则回退为“允许损坏的 UTF-8”，避免导入流程直接崩溃。
      try {
        return gbk.decode(bytes);
      } catch (_) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }

  /// 解析 TXT（每行一条）。
  static List<ParsedItem> _parseTxt(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final items = <ParsedItem>[];
    for (final line in lines) {
      final title = line.trim();
      if (title.isEmpty) continue;
      items.add(ParsedItem(title: title));
    }
    return items;
  }

  /// 解析 CSV（标题,备注,标签）。
  static List<ParsedItem> _parseCsv(String content) {
    final converter = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );
    final rows = converter.convert(content);
    if (rows.isEmpty) return const [];

    // 允许首行表头：标题,备注,标签
    var startIndex = 0;
    final firstRow = rows.first;
    if (firstRow.isNotEmpty) {
      final cells = firstRow.map((e) => (e ?? '').toString().trim()).toList();
      final hasHeader =
          cells.isNotEmpty &&
          (cells[0] == '标题' || cells[0].toLowerCase() == 'title');
      if (hasHeader) startIndex = 1;
    }

    final items = <ParsedItem>[];
    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      final title = row.isNotEmpty ? (row[0] ?? '').toString().trim() : '';
      final note = row.length >= 2 ? (row[1] ?? '').toString().trim() : '';
      final tagsRaw = row.length >= 3 ? (row[2] ?? '').toString().trim() : '';

      final tags = _parseTags(tagsRaw);
      if (title.isEmpty) {
        items.add(
          ParsedItem(
            title: '',
            note: note.isEmpty ? null : note,
            tags: tags,
            errorMessage: '标题为空',
          ),
        );
        continue;
      }

      items.add(
        ParsedItem(
          title: title,
          note: note.isEmpty ? null : note,
          tags: tags,
        ),
      );
    }
    return items;
  }

  /// 解析 Markdown（标题行以 # 开头）。
  static List<ParsedItem> _parseMarkdown(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final items = <ParsedItem>[];

    String? currentTitle;
    final noteLines = <String>[];

    void flush() {
      if (currentTitle == null) return;
      final title = currentTitle.trim();
      if (title.isEmpty) return;
      final note = noteLines.join('\n').trim();
      items.add(ParsedItem(title: title, note: note.isEmpty ? null : note));
      noteLines.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final match = RegExp(r'^(#+)\s+(.*)$').firstMatch(line);
      if (match != null) {
        // 新标题开始：提交上一条。
        flush();
        currentTitle = match.group(2)?.trim();
        continue;
      }

      // 非标题行：归入备注区域（允许空行以保留段落结构）。
      if (currentTitle != null) {
        noteLines.add(raw);
      }
    }
    flush();

    return items;
  }

  /// 标签分隔规则：支持中文/英文逗号，兼容 CSV 中常见的分号分隔。
  static List<String> _parseTags(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[，,;；]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
}
