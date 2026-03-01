/// 文件用途：备份/恢复工具（规范化 JSON、checksum、时间格式化、取消令牌等）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';

/// 备份/恢复取消异常。
///
/// 说明：用于在导出/导入流程中“用户点击取消”时中断流程，并由上层将其视为正常路径。
class BackupCanceledException implements Exception {
  const BackupCanceledException();

  @override
  String toString() => '已取消';
}

/// 取消令牌（用于导出/导入可中断能力）。
///
/// 说明：
/// - UI 层持有 token，并在用户点击“取消”时调用 [cancel]。
/// - 业务流程在关键阶段调用 [throwIfCanceled]，确保能及时中断并回滚。
class BackupCancelToken {
  bool _canceled = false;

  /// 标记为已取消。
  void cancel() => _canceled = true;

  /// 当前是否已取消。
  bool get isCanceled => _canceled;

  /// 若已取消则抛出 [BackupCanceledException]。
  void throwIfCanceled() {
    if (_canceled) throw const BackupCanceledException();
  }
}

/// 备份任务阶段（用于进度展示）。
enum BackupProgressStage {
  preparing,
  readingDatabase,
  encodingJson,
  writingFile,
  parsingFile,
  validatingChecksum,
  importingDatabase,
  rebuilding,
  completed,
}

/// 备份任务进度信息。
class BackupProgress {
  const BackupProgress({
    required this.stage,
    required this.message,
    this.percent,
  });

  /// 当前阶段。
  final BackupProgressStage stage;

  /// 展示用文案（中文）。
  final String message;

  /// 进度百分比（0-1，可空）。
  final double? percent;
}

/// 备份/恢复工具函数集合。
class BackupUtils {
  static final Sha256 _sha256 = Sha256();

  /// 生成“带时区偏移”的本地 ISO 字符串（符合 spec：`2026-02-28T10:30:00+08:00`）。
  ///
  /// 说明：
  /// - Dart 的 `DateTime.toIso8601String()` 对本地时间不会附带 offset，因此需手工拼接。
  /// - 该格式用于 UI 展示与跨时区一致性（配合 createdAtUtc）。
  static String formatLocalIsoWithOffset(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');

    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    final oh = abs.inHours.toString().padLeft(2, '0');
    final om = (abs.inMinutes % 60).toString().padLeft(2, '0');

    return '$y-$m-$d'
        'T$hh:$mm:$ss'
        '$sign$oh:$om';
  }

  /// 将任意 JSON 值规范化（递归排序 key；数组按 uuid 排序）。
  ///
  /// 规则（与 spec 一致）：
  /// 1) 所有对象的 key 按字母排序（递归处理）
  /// 2) 数组内元素若为 Map 且包含 uuid，则按 uuid 升序排序（递归处理）
  /// 3) 不引入额外空白（交给 jsonEncode 生成紧凑字符串）
  static dynamic normalizeJson(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).toList()..sort();
      final result = <String, dynamic>{};
      for (final k in keys) {
        result[k] = normalizeJson(value[k]);
      }
      return result;
    }

    if (value is List) {
      final normalized = value.map(normalizeJson).toList();

      final allHaveUuid =
          normalized.isNotEmpty &&
          normalized.every((e) => e is Map && e.containsKey('uuid'));

      if (allHaveUuid) {
        normalized.sort((a, b) {
          final au = (a as Map)['uuid']?.toString() ?? '';
          final bu = (b as Map)['uuid']?.toString() ?? '';
          return au.compareTo(bu);
        });
      }
      return normalized;
    }

    return value;
  }

  /// 将 `data` 字段规范化为稳定 JSON 字符串（用于 checksum）。
  ///
  /// 返回值：紧凑 JSON 字符串（UTF-8 编码后用于 payloadSize 与 SHA-256 计算）。
  static String canonicalizeDataJson(Map<String, dynamic> data) {
    final normalized = normalizeJson(data);
    if (normalized is! Map) {
      // 保护：理论上 data 必为 object；若被传入非 object，仍按 jsonEncode 输出。
      return jsonEncode(normalized);
    }
    return jsonEncode(normalized);
  }

  /// 在后台 Isolate 中计算 data 的 checksum 与 payloadSize（用于导出/导入校验）。
  ///
  /// 返回值：[BackupChecksumResult]。
  /// 说明：
  /// - 该函数会在 Isolate 内执行 JSON 规范化与 SHA-256 计算，避免阻塞 UI。
  /// - 仅返回必要信息；规范化后的 JSON 字符串用于诊断/预览（不建议在 UI 直接展示）。
  static Future<BackupChecksumResult> computeChecksumForDataInIsolate(
    Map<String, dynamic> data,
  ) async {
    final result = await Isolate.run(() async {
      final canonical = canonicalizeDataJson(data);
      final bytes = utf8.encode(canonical);
      final hash = await _sha256.hash(bytes);
      final checksum = 'sha256:${_toHex(hash.bytes)}';
      return <String, Object>{
        'canonical': canonical,
        'checksum': checksum,
        'payloadSize': bytes.length,
      };
    });

    return BackupChecksumResult(
      canonicalJson: result['canonical'] as String? ?? '',
      checksum: result['checksum'] as String? ?? '',
      payloadSize: result['payloadSize'] as int? ?? 0,
    );
  }

  /// 计算 `sha256:<hex>`。
  ///
  /// 说明：输入为规范化后的 `data` JSON 字符串（不包含 checksum 字段本身）。
  static Future<String> sha256Hex(String input) async {
    final bytes = utf8.encode(input);
    final hash = await _sha256.hash(bytes);
    return 'sha256:${_toHex(hash.bytes)}';
  }

  /// 计算规范化数据的 UTF-8 字节长度（用于 stats.payloadSize）。
  static int utf8BytesLength(String input) => utf8.encode(input).length;

  static String _toHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

/// checksum 计算结果。
class BackupChecksumResult {
  /// 构造函数。
  const BackupChecksumResult({
    required this.canonicalJson,
    required this.checksum,
    required this.payloadSize,
  });

  /// 规范化后的 data JSON 字符串。
  final String canonicalJson;

  /// `sha256:<hex>`。
  final String checksum;

  /// UTF-8 字节长度。
  final int payloadSize;
}
