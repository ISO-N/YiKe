/// 文件用途：领域实体 - 备份文件摘要（用于备份历史列表与导入预览）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:io';

import 'backup_file.dart';

/// 备份文件摘要信息。
class BackupSummaryEntity {
  /// 构造函数。
  const BackupSummaryEntity({
    required this.file,
    required this.fileName,
    required this.bytes,
    required this.schemaVersion,
    required this.appVersion,
    required this.backupId,
    required this.createdAt,
    required this.createdAtUtc,
    required this.checksum,
    required this.stats,
    required this.isSnapshot,
  });

  /// 备份文件句柄。
  final File file;

  /// 文件名（用于展示）。
  final String fileName;

  /// 文件大小（字节）。
  final int bytes;

  /// 备份格式版本。
  final String schemaVersion;

  /// 应用版本（用于展示）。
  final String appVersion;

  /// 备份 ID（用于重复导入检测）。
  final String backupId;

  /// 本地时间字符串（带 offset，用于展示）。
  final String createdAt;

  /// UTC 时间字符串（用于一致性与诊断）。
  final String createdAtUtc;

  /// `sha256:<hex>` 校验和（对 data 计算）。
  final String checksum;

  /// 数据统计信息。
  final BackupStatsEntity stats;

  /// 是否为导入前快照。
  final bool isSnapshot;
}
