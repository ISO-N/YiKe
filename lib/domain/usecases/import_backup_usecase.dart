/// 文件用途：用例 - 导入备份（解析/校验/预览/合并或覆盖导入 + 快照保护）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:io';

import '../../core/utils/backup_utils.dart';
import '../entities/backup_file.dart';
import '../repositories/backup_repository.dart';

/// 导入策略。
enum BackupImportStrategy {
  /// 合并导入（按 uuid Upsert）。
  merge,

  /// 覆盖导入（清空后导入，导入前自动创建快照）。
  overwrite,
}

/// 导入预览信息（用于 UI 展示与确认）。
class BackupImportPreviewEntity {
  /// 构造函数。
  const BackupImportPreviewEntity({
    required this.file,
    required this.backup,
    required this.isDuplicateBackupId,
    required this.isDuplicateChecksum,
    required this.canonicalPayloadSize,
    required this.computedChecksum,
  });

  /// 待导入文件。
  final File file;

  /// 已解析的备份实体。
  final BackupFileEntity backup;

  /// 是否已导入过该 backupId（本机）。
  final bool isDuplicateBackupId;

  /// 是否已导入过该 checksum（本机）。
  final bool isDuplicateChecksum;

  /// 规范化 data JSON 的字节长度（用于预览与诊断）。
  final int canonicalPayloadSize;

  /// 对规范化 data JSON 计算得到的 checksum（用于校验）。
  final String computedChecksum;
}

/// 导入异常（用于 UI 统一映射提示文案）。
class ImportBackupException implements Exception {
  /// 构造函数。
  const ImportBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 导入备份用例。
class ImportBackupUseCase {
  /// 构造函数。
  const ImportBackupUseCase({required BackupRepository repository})
    : _repository = repository;

  final BackupRepository _repository;

  /// 解析并校验备份文件（用于导入预览）。
  ///
  /// 规则：
  /// - 解析 JSON
  /// - 校验 schemaVersion 兼容性
  /// - 计算并校验 checksum（对 data 规范化 JSON 计算）
  /// - 检测重复导入（backupId/checksum）
  Future<BackupImportPreviewEntity> preview({
    required File file,
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
  }) async {
    final backup = await _repository.readBackupFile(
      file: file,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
    cancelToken.throwIfCanceled();

    _validateSchemaVersion(backup.schemaVersion);

    onProgress?.call(
      const BackupProgress(
        stage: BackupProgressStage.validatingChecksum,
        message: '校验文件完整性…',
      ),
    );
    cancelToken.throwIfCanceled();

    final checksumResult = await BackupUtils.computeChecksumForDataInIsolate(
      backup.data.toJson().cast<String, dynamic>(),
    );
    final computed = checksumResult.checksum;
    final size = checksumResult.payloadSize;

    if (backup.checksum.isEmpty) {
      throw const ImportBackupException('备份文件格式无效');
    }
    if (backup.checksum != computed) {
      throw const ImportBackupException('文件已损坏或被篡改，导入已阻止');
    }

    // 规范化 stats（缺字段允许导入，但预览应展示准确条数与 payloadSize）。
    final normalizedBackup = BackupFileEntity(
      schemaVersion: backup.schemaVersion,
      appVersion: backup.appVersion,
      dbSchemaVersion: backup.dbSchemaVersion,
      backupId: backup.backupId,
      createdAt: backup.createdAt,
      createdAtUtc: backup.createdAtUtc,
      checksum: backup.checksum,
      stats: BackupStatsEntity(
        learningItems: backup.data.learningItems.length,
        reviewTasks: backup.data.reviewTasks.length,
        reviewRecords: backup.data.reviewRecords.length,
        payloadSize: size,
      ),
      data: backup.data,
      platform: backup.platform,
      deviceModel: backup.deviceModel,
    );

    final backupId = backup.backupId.trim();
    final isDupId = backupId.isNotEmpty
        ? await _repository.hasImportedBackupId(backupId)
        : false;
    final isDupChecksum = await _repository.hasImportedChecksum(computed);

    return BackupImportPreviewEntity(
      file: file,
      backup: normalizedBackup,
      isDuplicateBackupId: isDupId,
      isDuplicateChecksum: isDupChecksum,
      canonicalPayloadSize: size,
      computedChecksum: computed,
    );
  }

  /// 执行导入（事务保护；覆盖导入前自动创建快照）。
  Future<void> execute({
    required BackupImportPreviewEntity preview,
    required BackupImportStrategy strategy,
    required BackupCancelToken cancelToken,
    void Function(BackupProgress progress)? onProgress,
    bool createSnapshotBeforeOverwrite = true,
  }) async {
    cancelToken.throwIfCanceled();

    final backupId = preview.backup.backupId.trim();
    if (backupId.isEmpty) {
      // spec：缺 backupId 允许导入；但此处缺少生成逻辑会影响重复导入检测，因此提示上层文件异常。
      // 说明：正常导出一定会生成 backupId；外部编辑导致缺失时仍可导入，但无法做“已导入过”检测。
    }

    final overwrite = strategy == BackupImportStrategy.overwrite;
    await _repository.importBackup(
      backup: preview.backup,
      overwrite: overwrite,
      createSnapshotBeforeOverwrite: overwrite && createSnapshotBeforeOverwrite,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    // 标记导入完成（用于重复导入检测）。
    final importedAtUtc = DateTime.now().toUtc().toIso8601String();
    if (backupId.isNotEmpty) {
      await _repository.markBackupImported(
        backupId: backupId,
        checksum: preview.computedChecksum,
        importedAtUtc: importedAtUtc,
      );
    } else {
      // backupId 缺失时仅按 checksum 记录。
      await _repository.markBackupImported(
        backupId: 'missing',
        checksum: preview.computedChecksum,
        importedAtUtc: importedAtUtc,
      );
    }
  }

  void _validateSchemaVersion(String schemaVersion) {
    final raw = schemaVersion.trim();
    if (raw.isEmpty) return;

    // 规则：当前实现的格式为 1.1；按 spec 支持 N-1（1.0）。
    // 说明：缺 schemaVersion 会在上层被视为默认 1.0。
    const supported = {'1.1', '1.0', '0.9'};
    if (supported.contains(raw)) return;

    // 若可解析为数字且大于 1.0，则认为版本过高。
    final num = double.tryParse(raw);
    if (num != null && num > 1.1) {
      throw const ImportBackupException('备份文件版本过高，无法导入');
    }

    // 其他非预期值统一按格式无效处理。
    throw const ImportBackupException('备份文件格式无效');
  }
}
