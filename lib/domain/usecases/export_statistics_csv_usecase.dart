/// 文件用途：用例 - 导出统计数据为 CSV（按天聚合）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/utils/csv_export_utils.dart';
import '../entities/task_day_stats.dart';
import '../repositories/review_task_repository.dart';

/// 统计 CSV 导出结果。
class ExportStatisticsCsvResult {
  /// 构造函数。
  const ExportStatisticsCsvResult({
    required this.file,
    required this.fileName,
    required this.bytes,
    required this.start,
    required this.end,
  });

  /// 导出文件。
  final File file;

  /// 文件名（不含路径）。
  final String fileName;

  /// 文件大小（字节）。
  final int bytes;

  /// 导出范围起点（包含）。
  final DateTime start;

  /// 导出范围终点（不包含）。
  final DateTime end;
}

/// 导出统计数据 CSV 用例。
///
/// 说明：
/// - 导出为“按天聚合”的统计数据（不包含内容详情，无隐私字段）
/// - 编码：UTF-8 无 BOM
/// - 分隔符：逗号
class ExportStatisticsCsvUseCase {
  /// 构造函数。
  const ExportStatisticsCsvUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行导出。
  ///
  /// 参数：
  /// - [year] 导出年份（导出范围为 1/1 00:00 到 次年 1/1 00:00）
  /// - [outputPath] 可选输出路径；为空时写入临时目录
  ///
  /// 返回值：[ExportStatisticsCsvResult]。
  /// 异常：文件写入失败或数据库查询失败时可能抛出异常。
  Future<ExportStatisticsCsvResult> execute({
    required int year,
    String? outputPath,
  }) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final Map<DateTime, TaskDayStats> statsByDay = await _reviewTaskRepository
        .getTaskDayStatsInRange(start, end);
    final csv = CsvExportUtils.buildDailyStatisticsCsv(
      start: start,
      end: end,
      statsByDay: statsByDay,
    );
    final bytes = CsvExportUtils.toUtf8Bytes(csv);

    final fileName = 'yike_statistics_$year.csv';
    final file = await _resolveOutputFile(
      fileName: fileName,
      outputPath: outputPath,
    );
    await file.writeAsBytes(bytes, flush: true);

    return ExportStatisticsCsvResult(
      file: file,
      fileName: fileName,
      bytes: bytes.length,
      start: start,
      end: end,
    );
  }

  Future<File> _resolveOutputFile({
    required String fileName,
    String? outputPath,
  }) async {
    final path = outputPath?.trim();
    if (path != null && path.isNotEmpty) {
      return File(path);
    }

    final dir = await getTemporaryDirectory();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }
}
