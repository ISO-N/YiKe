/// 文件用途：备份与恢复页面（v1.5），包含导出/导入/备份历史/导入前快照入口。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/backup_file.dart';
import '../../../domain/entities/backup_summary.dart';
import '../../../domain/usecases/import_backup_usecase.dart';
import '../../providers/backup_provider.dart';
import '../../widgets/glass_card.dart';

/// 备份与恢复页面。
class BackupPage extends ConsumerStatefulWidget {
  /// 构造函数。
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupProvider);
    final notifier = ref.read(backupProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份与恢复'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: state.isRunning ? null : notifier.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('重要提示', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '备份文件为明文 JSON，可能包含敏感学习内容，建议妥善保管。',
                      style: AppTypography.bodySecondary(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.isRunning) ...[
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.progress?.message ?? '处理中…',
                              style: AppTypography.body(context),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            LinearProgressIndicator(
                              value: state.progress?.percent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton(
                        onPressed: notifier.cancelCurrentOperation,
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('快捷操作', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: state.isRunning
                                ? null
                                : () async {
                                    final ok = await _confirmPlaintextExport(
                                      context,
                                    );
                                    if (!ok) return;
                                    final result = await notifier
                                        .exportBackup();
                                    if (!context.mounted || result == null) {
                                      return;
                                    }
                                    _showSnack(
                                      context,
                                      '备份成功：${result.fileName}（${_formatBytes(result.bytes)}）',
                                      actionLabel: '分享/另存为',
                                      onAction: () =>
                                          _showShareSheet(context, result),
                                    );
                                  },
                            icon: const Icon(Icons.download),
                            label: const Text('导出备份'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: state.isRunning
                                ? null
                                : () async {
                                    final file = await _pickBackupFile();
                                    if (!context.mounted) return;
                                    if (file == null) {
                                      _showSnack(context, '已取消');
                                      return;
                                    }
                                    await _previewAndImport(context, file);
                                  },
                            icon: const Icon(Icons.upload),
                            label: const Text('导入数据'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.snapshot != null) ...[
              _SnapshotCard(
                snapshot: state.snapshot!,
                onRestore: state.isRunning
                    ? null
                    : () async {
                        final confirmed = await _confirmRestoreSnapshot(
                          context,
                          state.snapshot!,
                        );
                        if (!confirmed || !context.mounted) return;
                        await _restoreSnapshot(context, state.snapshot!);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('备份历史', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.backups.isEmpty)
                      Text('暂无备份', style: AppTypography.bodySecondary(context))
                    else
                      ...state.backups.map(
                        (b) => _BackupTile(
                          summary: b,
                          onRestore: state.isRunning
                              ? null
                              : () => _previewAndImport(context, b.file),
                          onShare: state.isRunning
                              ? null
                              : () => _showShareSheet(context, b),
                          onDelete: state.isRunning
                              ? null
                              : () async {
                                  final ok = await _confirmDeleteBackup(
                                    context,
                                    b,
                                  );
                                  if (!ok) return;
                                  await ref
                                      .read(backupProvider.notifier)
                                      .deleteBackup(b);
                                  if (!context.mounted) return;
                                  _showSnack(context, '已删除');
                                },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '错误：${state.errorMessage}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
            if (state.message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    state.message!,
                    style: AppTypography.bodySecondary(context),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['yikebackup'],
      withData: false,
    );
    if (result == null) return null;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  Future<void> _previewAndImport(BuildContext context, File file) async {
    final notifier = ref.read(backupProvider.notifier);
    final preview = await notifier.previewImport(file);
    if (!context.mounted || preview == null) return;

    final chosen = await _showImportPreviewDialog(context, preview);
    if (!context.mounted || chosen == null) return;

    if (chosen == BackupImportStrategy.overwrite) {
      final stats = await ref
          .read(backupRepositoryProvider)
          .getCurrentUserDataStats();
      if (!context.mounted) return;
      final confirmed = await _confirmOverwriteImport(context, stats: stats);
      if (!context.mounted || !confirmed) return;
    }

    final ok = await notifier.importBackup(
      preview: preview,
      strategy: chosen,
      createSnapshotBeforeOverwrite: true,
    );
    if (!context.mounted) return;

    if (ok) {
      _showSnack(context, '导入成功');
    } else {
      final snapshot = ref.read(backupProvider).snapshot;
      if (snapshot != null) {
        final restore = await _confirmRestoreAfterFailure(context, snapshot);
        if (!context.mounted || !restore) return;
        await _restoreSnapshot(context, snapshot);
      } else {
        _showSnack(context, '导入失败');
      }
    }
  }

  Future<void> _restoreSnapshot(
    BuildContext context,
    BackupSummaryEntity snapshot,
  ) async {
    final notifier = ref.read(backupProvider.notifier);
    final preview = await notifier.previewImport(snapshot.file);
    if (!context.mounted || preview == null) return;

    final ok = await notifier.importBackup(
      preview: preview,
      strategy: BackupImportStrategy.overwrite,
      createSnapshotBeforeOverwrite: false,
    );
    if (!context.mounted) return;
    _showSnack(context, ok ? '已从快照恢复' : '快照恢复失败');
  }

  Future<void> _showShareSheet(
    BuildContext parentContext,
    BackupSummaryEntity summary,
  ) async {
    await showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('分享/另存为', style: AppTypography.h2(sheetContext)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '外部文件不受应用管理，请自行妥善保管。',
                  style: AppTypography.bodySecondary(sheetContext),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('分享'),
                  subtitle: const Text('通过系统分享发送到其他应用/设备'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await Share.shareXFiles([
                      XFile(summary.file.path),
                    ], text: '忆刻备份（格式 ${summary.schemaVersion}）');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: const Text('另存为…'),
                  subtitle: const Text('保存到你选择的目录（不纳入备份历史）'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final target = await FilePicker.platform.saveFile(
                      dialogTitle: '另存为',
                      fileName: summary.fileName,
                      type: FileType.custom,
                      allowedExtensions: const ['yikebackup'],
                    );
                    if (!parentContext.mounted) return;
                    if (target == null || target.isEmpty) {
                      _showSnack(parentContext, '已取消');
                      return;
                    }
                    try {
                      await summary.file.copy(target);
                      if (!parentContext.mounted) return;
                      _showSnack(parentContext, '已保存到：$target');
                    } catch (e) {
                      if (!parentContext.mounted) return;
                      _showSnack(parentContext, '保存失败：$e');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmPlaintextExport(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导出备份'),
          content: const Text('备份文件为明文 JSON，可能包含敏感学习内容。建议妥善保管。\n\n是否继续导出？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<BackupImportStrategy?> _showImportPreviewDialog(
    BuildContext context,
    BackupImportPreviewEntity preview,
  ) async {
    return showDialog<BackupImportStrategy>(
      context: context,
      builder: (context) {
        var strategy = BackupImportStrategy.merge;
        return StatefulBuilder(
          builder: (context, setState) {
            final b = preview.backup;
            return AlertDialog(
              title: const Text('导入预览'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('备份时间：${_formatBackupTime(b.createdAtUtc)}'),
                    Text(
                      '应用版本：${b.appVersion.isEmpty ? 'unknown' : b.appVersion}',
                    ),
                    Text('格式版本：${b.schemaVersion}'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '学习内容：${b.stats.learningItems} 条\n'
                      '复习任务：${b.stats.reviewTasks} 条\n'
                      '复习记录：${b.stats.reviewRecords} 条\n'
                      '数据大小：${_formatBytes(preview.canonicalPayloadSize)}',
                      style: AppTypography.bodySecondary(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (preview.isDuplicateBackupId ||
                        preview.isDuplicateChecksum)
                      Text(
                        '提示：该备份文件已导入过，重复导入不会产生重复数据（合并策略）。',
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    if (_platformMismatchHint(b.platform) != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _platformMismatchHint(b.platform)!,
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text('导入策略', style: AppTypography.h2(context)),
                    SegmentedButton<BackupImportStrategy>(
                      segments: const [
                        ButtonSegment(
                          value: BackupImportStrategy.merge,
                          label: Text('合并（推荐）'),
                          icon: Icon(Icons.merge_type),
                        ),
                        ButtonSegment(
                          value: BackupImportStrategy.overwrite,
                          label: Text('覆盖'),
                          icon: Icon(Icons.warning_amber),
                        ),
                      ],
                      selected: {strategy},
                      onSelectionChanged: (s) => setState(() {
                        strategy = s.first;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      strategy == BackupImportStrategy.merge
                          ? '合并：按 uuid 去重，存在则更新，不存在则插入（默认推荐）。'
                          : '覆盖：清空现有数据后导入（会自动创建导入前快照）。',
                      style: AppTypography.bodySecondary(context),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(strategy),
                  child: const Text('确认导入'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmOverwriteImport(
    BuildContext context, {
    required BackupStatsEntity stats,
  }) async {
    final itemCount = stats.learningItems;
    final taskCount = stats.reviewTasks;
    final recordCount = stats.reviewRecords;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认覆盖导入'),
          content: Text(
            '覆盖导入将删除当前数据：\n'
            '学习内容 $itemCount 条\n'
            '复习任务 $taskCount 条\n'
            '复习记录 $recordCount 条\n\n'
            '应用将自动创建导入前快照，导入失败可回滚。\n\n是否继续？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _confirmDeleteBackup(
    BuildContext context,
    BackupSummaryEntity summary,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除备份'),
          content: Text('确定删除备份文件：${summary.fileName}？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _confirmRestoreSnapshot(
    BuildContext context,
    BackupSummaryEntity snapshot,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('恢复快照'),
          content: Text(
            '将从导入前快照恢复数据：\n${snapshot.fileName}\n\n该操作会覆盖当前数据，是否继续？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _confirmRestoreAfterFailure(
    BuildContext context,
    BackupSummaryEntity snapshot,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入失败'),
          content: const Text('是否从“导入前快照”恢复数据？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('恢复快照'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showSnack(
    BuildContext context,
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  String _formatBackupTime(String createdAtUtc) {
    try {
      final dt = DateTime.parse(createdAtUtc).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return createdAtUtc;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)}KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)}MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)}GB';
  }

  String? _platformMismatchHint(String? backupPlatform) {
    if (backupPlatform == null || backupPlatform.trim().isEmpty) return null;
    final current = _currentPlatformName();
    if (current == null) return null;
    if (backupPlatform.trim() == current) return null;
    return '提示：该备份来自 $backupPlatform，当前设备为 $current，跨平台导入可能存在兼容性问题，是否继续？';
  }

  String? _currentPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'desktop';
    }
    return null;
  }
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({
    required this.summary,
    required this.onRestore,
    required this.onShare,
    required this.onDelete,
  });

  final BackupSummaryEntity summary;
  final VoidCallback? onRestore;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: Text(_formatTime(summary.createdAtUtc)),
          subtitle: Text(
            '应用 ${summary.appVersion} / 格式 ${summary.schemaVersion}',
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              TextButton(onPressed: onRestore, child: const Text('恢复')),
              TextButton(onPressed: onShare, child: const Text('分享')),
              TextButton(
                onPressed: onDelete,
                child: const Text(
                  '删除',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _formatTime(String utcIso) {
    try {
      final dt = DateTime.parse(utcIso).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return utcIso;
    }
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot, required this.onRestore});

  final BackupSummaryEntity snapshot;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('[导入前快照]', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '时间：${_formatTime(snapshot.createdAtUtc)}',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onRestore,
                child: const Text('恢复'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String utcIso) {
    try {
      final dt = DateTime.parse(utcIso).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return utcIso;
    }
  }
}
