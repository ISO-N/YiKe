/// 文件用途：用例 - 获取备份历史列表（应用托管目录）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../entities/backup_summary.dart';
import '../repositories/backup_repository.dart';

/// 获取备份列表用例。
class GetBackupListUseCase {
  /// 构造函数。
  const GetBackupListUseCase({required BackupRepository repository})
    : _repository = repository;

  final BackupRepository _repository;

  /// 获取备份历史列表（按时间倒序）。
  Future<List<BackupSummaryEntity>> execute() => _repository.getBackupList();
}
