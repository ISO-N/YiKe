/// 文件用途：备份与恢复状态管理（v1.5），负责导出/导入/备份历史与快照入口。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/backup_utils.dart';
import '../../di/providers.dart';
import '../../domain/entities/backup_summary.dart';
import '../../domain/usecases/import_backup_usecase.dart';
import '../../infrastructure/notification/notification_service.dart';
import 'calendar_provider.dart';
import 'home_tasks_provider.dart';
import 'settings_provider.dart';
import 'statistics_provider.dart';

/// 备份与恢复 UI 状态。
class BackupUiState {
  const BackupUiState({
    required this.isRunning,
    required this.backups,
    this.snapshot,
    this.progress,
    this.message,
    this.errorMessage,
    this.lastExported,
  });

  final bool isRunning;
  final List<BackupSummaryEntity> backups;
  final BackupSummaryEntity? snapshot;
  final BackupProgress? progress;
  final String? message;
  final String? errorMessage;
  final BackupSummaryEntity? lastExported;

  factory BackupUiState.initial() =>
      const BackupUiState(isRunning: false, backups: <BackupSummaryEntity>[]);

  BackupUiState copyWith({
    bool? isRunning,
    List<BackupSummaryEntity>? backups,
    BackupSummaryEntity? snapshot,
    BackupProgress? progress,
    BackupSummaryEntity? lastExported,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
    bool clearProgress = false,
    bool clearSnapshot = false,
    bool clearLastExported = false,
  }) {
    return BackupUiState(
      isRunning: isRunning ?? this.isRunning,
      backups: backups ?? this.backups,
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      progress: clearProgress ? null : (progress ?? this.progress),
      lastExported: clearLastExported
          ? null
          : (lastExported ?? this.lastExported),
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 备份与恢复 Notifier。
class BackupNotifier extends StateNotifier<BackupUiState> {
  BackupNotifier(this._ref) : super(BackupUiState.initial()) {
    load();
  }

  final Ref _ref;
  BackupCancelToken? _token;

  /// 刷新备份历史与快照。
  Future<void> load() async {
    try {
      final list = await _ref.read(getBackupListUseCaseProvider).execute();
      final snapshot = await _ref
          .read(backupRepositoryProvider)
          .getLatestSnapshot();
      state = state.copyWith(
        backups: list,
        snapshot: snapshot,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// 取消当前导出/导入操作。
  void cancelCurrentOperation() {
    _token?.cancel();
  }

  /// 执行导出（写入应用私有目录，纳入备份历史）。
  Future<BackupSummaryEntity?> exportBackup() async {
    final token = BackupCancelToken();
    _token = token;
    state = state.copyWith(
      isRunning: true,
      clearMessage: true,
      clearError: true,
      progress: const BackupProgress(
        stage: BackupProgressStage.preparing,
        message: '准备导出…',
      ),
    );

    try {
      final result = await _ref
          .read(exportBackupUseCaseProvider)
          .execute(
            cancelToken: token,
            onProgress: (p) => state = state.copyWith(progress: p),
          );
      state = state.copyWith(
        isRunning: false,
        lastExported: result,
        progress: const BackupProgress(
          stage: BackupProgressStage.completed,
          message: '备份成功',
        ),
        message: '备份成功',
      );
      await load();
      return result;
    } on BackupCanceledException {
      state = state.copyWith(
        isRunning: false,
        clearProgress: true,
        message: '已取消',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isRunning: false, errorMessage: e.toString());
      return null;
    } finally {
      _token = null;
    }
  }

  /// 解析并校验导入文件（用于预览）。
  Future<BackupImportPreviewEntity?> previewImport(File file) async {
    final token = BackupCancelToken();
    _token = token;
    state = state.copyWith(
      isRunning: true,
      clearMessage: true,
      clearError: true,
      progress: const BackupProgress(
        stage: BackupProgressStage.parsingFile,
        message: '解析备份文件…',
      ),
    );

    try {
      final preview = await _ref
          .read(importBackupUseCaseProvider)
          .preview(
            file: file,
            cancelToken: token,
            onProgress: (p) => state = state.copyWith(progress: p),
          );
      state = state.copyWith(isRunning: false, clearProgress: true);
      return preview;
    } on BackupCanceledException {
      state = state.copyWith(
        isRunning: false,
        clearProgress: true,
        message: '已取消',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        clearProgress: true,
        errorMessage: e.toString(),
      );
      return null;
    } finally {
      _token = null;
    }
  }

  /// 执行导入（合并或覆盖）。
  Future<bool> importBackup({
    required BackupImportPreviewEntity preview,
    required BackupImportStrategy strategy,
    bool createSnapshotBeforeOverwrite = true,
  }) async {
    final token = BackupCancelToken();
    _token = token;
    state = state.copyWith(
      isRunning: true,
      clearMessage: true,
      clearError: true,
      progress: const BackupProgress(
        stage: BackupProgressStage.importingDatabase,
        message: '写入数据库…',
      ),
    );

    try {
      await _ref
          .read(importBackupUseCaseProvider)
          .execute(
            preview: preview,
            strategy: strategy,
            cancelToken: token,
            createSnapshotBeforeOverwrite: createSnapshotBeforeOverwrite,
            onProgress: (p) => state = state.copyWith(progress: p),
          );

      // 导入成功后清理通知残留（通知会在后台任务/页面刷新时按新数据重新生成）。
      try {
        await NotificationService.instance.cancelAll();
      } catch (_) {
        // 通知插件不可用或取消失败时不阻塞主流程。
      }
      state = state.copyWith(
        isRunning: false,
        clearProgress: true,
        message: '导入成功',
      );
      _invalidateCoreProviders();
      await load();
      return true;
    } on BackupCanceledException {
      state = state.copyWith(
        isRunning: false,
        clearProgress: true,
        message: '已取消',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        clearProgress: true,
        errorMessage: e.toString(),
      );
      await load();
      return false;
    } finally {
      _token = null;
    }
  }

  /// 删除备份历史文件。
  Future<void> deleteBackup(BackupSummaryEntity summary) async {
    try {
      await _ref.read(backupRepositoryProvider).deleteBackup(summary.file);
      state = state.copyWith(message: '已删除');
      await load();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void _invalidateCoreProviders() {
    // 导入后需要刷新：首页/日历/统计/设置（并触发小组件同步）。
    _ref.invalidate(homeTasksProvider);
    _ref.invalidate(calendarProvider);
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(settingsProvider);
  }
}

/// 备份与恢复 Provider。
final backupProvider = StateNotifierProvider<BackupNotifier, BackupUiState>(
  (ref) => BackupNotifier(ref),
);
