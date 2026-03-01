/// 文件用途：用例 - 导出备份（应用托管备份历史 + checksum）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../../core/utils/backup_utils.dart';
import '../entities/backup_summary.dart';
import '../repositories/backup_repository.dart';

/// 导出备份用例（F15：备份与恢复）。
class ExportBackupUseCase {
  /// 构造函数。
  const ExportBackupUseCase({required BackupRepository repository})
    : _repository = repository;

  final BackupRepository _repository;

  /// 执行导出。
  ///
  /// 参数：
  /// - [cancelToken] 取消令牌
  /// - [onProgress] 进度回调
  /// 返回值：导出的备份摘要（含文件句柄）。
  Future<BackupSummaryEntity> execute({
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
  }) {
    return _repository.exportBackup(
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }
}
