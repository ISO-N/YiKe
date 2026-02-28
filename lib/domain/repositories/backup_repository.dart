/// 文件用途：领域仓储接口 - 备份/恢复（导出/导入/历史管理）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:io';

import '../../core/utils/backup_utils.dart';
import '../entities/backup_file.dart';
import '../entities/backup_summary.dart';

/// 备份仓储接口。
///
/// 说明：
/// - 导出：读取数据库 → 生成 JSON → 写入应用私有目录（备份历史）
/// - 导入：解析文件 → 校验 checksum → 按策略写入数据库（事务）
abstract class BackupRepository {
  /// 导出备份文件到“应用托管备份历史”。
  ///
  /// 参数：
  /// - [cancelToken] 取消令牌（用于可中断/可取消）
  /// - [onProgress] 进度回调（用于 UI 展示阶段与进度）
  /// 返回值：[BackupSummaryEntity]（含文件与元信息）。
  Future<BackupSummaryEntity> exportBackup({
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
  });

  /// 获取备份历史列表（仅应用托管目录）。
  Future<List<BackupSummaryEntity>> getBackupList();

  /// 删除一个备份历史文件。
  Future<void> deleteBackup(File file);

  /// 读取并解析备份文件（用于导入预览/执行导入）。
  ///
  /// 说明：上层需在读取后自行校验版本/策略等。
  Future<BackupFileEntity> readBackupFile({
    required File file,
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
  });

  /// 获取导入前快照（若不存在返回 null）。
  Future<BackupSummaryEntity?> getLatestSnapshot();

  /// 获取当前本机可备份数据统计（用于覆盖导入二次确认提示）。
  ///
  /// 说明：仅统计备份范围内的数据（learning_items/review_tasks/review_records）。
  Future<BackupStatsEntity> getCurrentUserDataStats();

  /// 创建“覆盖导入前快照”（覆盖式，仅保留 1 份）。
  ///
  /// 返回值：快照摘要（含文件句柄）。
  Future<BackupSummaryEntity> createImportSnapshot({
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
  });

  /// 查询是否已导入过该 backupId（本机去重）。
  Future<bool> hasImportedBackupId(String backupId);

  /// 查询是否已导入过该 checksum（本机去重）。
  Future<bool> hasImportedChecksum(String checksum);

  /// 标记一次导入完成（用于重复导入检测）。
  Future<void> markBackupImported({
    required String backupId,
    required String checksum,
    required String importedAtUtc,
  });

  /// 执行导入（需在上层完成解析/校验/预览与策略确认）。
  ///
  /// 参数：
  /// - [backup] 已解析的备份文件实体
  /// - [overwrite] true=覆盖导入（清空后导入）；false=合并导入（按 uuid Upsert）
  /// - [createSnapshotBeforeOverwrite] 覆盖导入前是否自动创建快照
  Future<void> importBackup({
    required BackupFileEntity backup,
    required bool overwrite,
    required bool createSnapshotBeforeOverwrite,
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
  });
}
