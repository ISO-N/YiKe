/// 文件用途：用例 - 数据导出（JSON/CSV），用于备份与分享（F8）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../entities/learning_item.dart';
import '../entities/review_task.dart';
import '../repositories/learning_item_repository.dart';
import '../repositories/review_task_repository.dart';

/// 数据导出异常。
class ExportException implements Exception {
  /// 构造函数。
  const ExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 导出格式。
enum ExportFormat { json, csv }

/// 导出参数。
class ExportParams {
  /// 构造函数。
  const ExportParams({
    required this.format,
    required this.includeItems,
    required this.includeTasks,
  });

  final ExportFormat format;
  final bool includeItems;
  final bool includeTasks;
}

/// 导出预览（用于 UI 展示数据量）。
class ExportPreview {
  const ExportPreview({required this.itemCount, required this.taskCount});

  final int itemCount;
  final int taskCount;

  int get totalCount => itemCount + taskCount;
}

/// 导出结果。
class ExportResult {
  const ExportResult({
    required this.file,
    required this.itemCount,
    required this.taskCount,
    required this.exportedAt,
    required this.bytes,
  });

  final File file;
  final int itemCount;
  final int taskCount;
  final DateTime exportedAt;
  final int bytes;

  int get totalCount => itemCount + taskCount;

  String get fileName =>
      file.uri.pathSegments.isEmpty ? file.path : file.uri.pathSegments.last;
}

/// 数据导出用例（F8）。
class ExportDataUseCase {
  /// 构造函数。
  const ExportDataUseCase({
    required LearningItemRepository learningItemRepository,
    required ReviewTaskRepository reviewTaskRepository,
  }) : _learningItemRepository = learningItemRepository,
       _reviewTaskRepository = reviewTaskRepository;

  final LearningItemRepository _learningItemRepository;
  final ReviewTaskRepository _reviewTaskRepository;

  /// 预览导出数据量（不写文件）。
  ///
  /// 返回值：导出条目数量预览。
  Future<ExportPreview> preview(ExportParams params) async {
    final includeAny = params.includeItems || params.includeTasks;
    if (!includeAny) {
      throw const ExportException('请至少选择一种导出内容');
    }

    final items = params.includeItems
        ? (await _learningItemRepository.getAll())
              .where((e) => !e.isMockData)
              .toList()
        : const <LearningItemEntity>[];
    final tasks = params.includeTasks
        ? (await _reviewTaskRepository.getAllTasks())
              .where((e) => !e.isMockData)
              .toList()
        : const <ReviewTaskEntity>[];

    return ExportPreview(itemCount: items.length, taskCount: tasks.length);
  }

  /// 执行导出并写入本地文件。
  ///
  /// 返回值：[ExportResult]（含文件路径与记录数）。
  /// 异常：导出失败时抛出 [ExportException] 或底层 IO 异常。
  Future<ExportResult> execute(ExportParams params) async {
    final includeAny = params.includeItems || params.includeTasks;
    if (!includeAny) {
      throw const ExportException('请至少选择一种导出内容');
    }

    final exportedAt = DateTime.now();
    final items = params.includeItems
        ? (await _learningItemRepository.getAll())
              .where((e) => !e.isMockData)
              .toList()
        : const <LearningItemEntity>[];
    final tasks = params.includeTasks
        ? (await _reviewTaskRepository.getAllTasks())
              .where((e) => !e.isMockData)
              .toList()
        : const <ReviewTaskEntity>[];

    if (items.isEmpty && tasks.isEmpty) {
      throw const ExportException('暂无可导出的数据');
    }

    final content = switch (params.format) {
      ExportFormat.json => _toJson(
        items: items,
        tasks: tasks,
        exportedAt: exportedAt,
      ),
      ExportFormat.csv => _toCsv(
        items: items,
        tasks: tasks,
        exportedAt: exportedAt,
      ),
    };

    final file = await _saveToFile(
      content: content,
      format: params.format,
      exportedAt: exportedAt,
    );
    final bytes = await file.length();

    return ExportResult(
      file: file,
      itemCount: items.length,
      taskCount: tasks.length,
      exportedAt: exportedAt,
      bytes: bytes,
    );
  }

  String _toJson({
    required List<LearningItemEntity> items,
    required List<ReviewTaskEntity> tasks,
    required DateTime exportedAt,
  }) {
    return jsonEncode({
      'version': '2.0',
      'exportedAt': exportedAt.toIso8601String(),
      'items': items.map(_itemToJson).toList(),
      'tasks': tasks.map(_taskToJson).toList(),
    });
  }

  Map<String, Object?> _itemToJson(LearningItemEntity item) {
    return {
      'id': item.id,
      'title': item.title,
      'note': item.note,
      'tags': item.tags,
      'learningDate': item.learningDate.toIso8601String(),
      'createdAt': item.createdAt.toIso8601String(),
      'isDeleted': item.isDeleted,
      'deletedAt': item.deletedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> _taskToJson(ReviewTaskEntity task) {
    return {
      'id': task.id,
      'learningItemId': task.learningItemId,
      'reviewRound': task.reviewRound,
      'scheduledDate': task.scheduledDate.toIso8601String(),
      'status': task.status.toDbValue(),
      'completedAt': task.completedAt?.toIso8601String(),
      'skippedAt': task.skippedAt?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
    };
  }

  String _toCsv({
    required List<LearningItemEntity> items,
    required List<ReviewTaskEntity> tasks,
    required DateTime exportedAt,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('忆刻数据导出');
    buffer.writeln('版本,2.0');
    buffer.writeln('导出时间,${exportedAt.toIso8601String()}');
    buffer.writeln();

    if (items.isNotEmpty) {
      buffer.writeln('学习内容');
      buffer.writeln('id,title,note,tags,learningDate,createdAt,isDeleted,deletedAt');
      for (final item in items) {
        buffer
          ..write(_csvInt(item.id))
          ..write(',')
          ..write(_csvText(item.title))
          ..write(',')
          ..write(_csvText(item.note ?? ''))
          ..write(',')
          ..write(_csvText(item.tags.join(';')))
          ..write(',')
          ..write(_csvText(item.learningDate.toIso8601String()))
          ..write(',')
          ..write(_csvText(item.createdAt.toIso8601String()))
          ..write(',')
          ..write(_csvText(item.isDeleted.toString()))
          ..write(',')
          ..writeln(_csvText(item.deletedAt?.toIso8601String() ?? ''));
      }
      buffer.writeln();
    }

    if (tasks.isNotEmpty) {
      buffer.writeln('复习任务');
      buffer.writeln(
        'id,learningItemId,reviewRound,scheduledDate,status,completedAt,skippedAt,createdAt',
      );
      for (final task in tasks) {
        buffer
          ..write(_csvInt(task.id))
          ..write(',')
          ..write(_csvInt(task.learningItemId))
          ..write(',')
          ..write(task.reviewRound)
          ..write(',')
          ..write(_csvText(task.scheduledDate.toIso8601String()))
          ..write(',')
          ..write(_csvText(task.status.toDbValue()))
          ..write(',')
          ..write(_csvText(task.completedAt?.toIso8601String() ?? ''))
          ..write(',')
          ..write(_csvText(task.skippedAt?.toIso8601String() ?? ''))
          ..write(',')
          ..writeln(_csvText(task.createdAt.toIso8601String()));
      }
    }

    return buffer.toString();
  }

  String _csvInt(int? v) => v?.toString() ?? '';

  String _csvText(String v) {
    // RFC4180：若包含逗号/引号/换行，则必须加引号，并将引号转义为双引号。
    final needQuote =
        v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r');
    if (!needQuote) return v;
    final escaped = v.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<File> _saveToFile({
    required String content,
    required ExportFormat format,
    required DateTime exportedAt,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    // 加入毫秒，避免短时间内多次导出导致文件名冲突。
    final stamp = DateFormat('yyyyMMdd_HHmmss_SSS').format(exportedAt);
    final ext = format == ExportFormat.json ? 'json' : 'csv';
    final file = File(
      '${dir.path}${Platform.pathSeparator}yike_export_$stamp.$ext',
    );
    await file.writeAsString(content, encoding: utf8, flush: true);
    return file;
  }
}
