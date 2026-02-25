/// 文件用途：数据导出页面（F8），支持 JSON/CSV 导出并通过系统分享。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../di/providers.dart';
import '../../../domain/usecases/export_data_usecase.dart';
import '../../widgets/glass_card.dart';

/// 数据导出页面（Modal）。
class ExportPage extends ConsumerStatefulWidget {
  /// 构造函数。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  ExportFormat _format = ExportFormat.json;
  bool _includeItems = true;
  bool _includeTasks = true;
  bool _isExporting = false;
  bool _isPreviewLoading = true;
  ExportPreview? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  ExportParams get _params => ExportParams(
    format: _format,
    includeItems: _includeItems,
    includeTasks: _includeTasks,
  );

  Future<void> _loadPreview() async {
    setState(() {
      _isPreviewLoading = true;
      _error = null;
    });

    try {
      final preview = await ref
          .read(exportDataUseCaseProvider)
          .preview(_params);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isPreviewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreviewLoading = false;
        _error = e.toString();
        _preview = null;
      });
    }
  }

  Future<void> _doExport() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final result = await ref.read(exportDataUseCaseProvider).execute(_params);

      // 系统分享文件
      await Share.shareXFiles([
        XFile(result.file.path),
      ], text: '忆刻数据导出（${result.totalCount} 条）');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导出成功：${result.fileName}（${_formatBytes(result.bytes)}）',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final canExport =
        !_isExporting &&
        !_isPreviewLoading &&
        (_includeItems || _includeTasks) &&
        (preview != null && preview.totalCount > 0);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.exportData)),
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
                    const Text('导出格式', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ExportFormat>(
                      segments: const [
                        ButtonSegment(
                          value: ExportFormat.json,
                          label: Text('JSON'),
                          icon: Icon(Icons.data_object),
                        ),
                        ButtonSegment(
                          value: ExportFormat.csv,
                          label: Text('CSV'),
                          icon: Icon(Icons.table_chart),
                        ),
                      ],
                      selected: {_format},
                      onSelectionChanged: (selection) {
                        setState(() => _format = selection.first);
                        _loadPreview();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _format == ExportFormat.json
                          ? '完整数据，适合备份与恢复'
                          : '表格数据，适合分析与查看',
                      style: AppTypography.bodySecondary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('导出内容', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      title: const Text('学习内容'),
                      value: _includeItems,
                      onChanged: (v) {
                        setState(() => _includeItems = v ?? false);
                        _loadPreview();
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('复习任务'),
                      value: _includeTasks,
                      onChanged: (v) {
                        setState(() => _includeTasks = v ?? false);
                        _loadPreview();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '提示：至少选择一项；应用设置不会被导出。',
                      style: AppTypography.bodySecondary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('数据预览', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.sm),
                    if (_isPreviewLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      Text(
                        '预览失败：$_error',
                        style: const TextStyle(color: AppColors.error),
                      )
                    else if (preview == null)
                      const Text('暂无数据', style: AppTypography.bodySecondary)
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _PreviewTile(
                              title: '学习内容',
                              value: preview.itemCount,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _PreviewTile(
                              title: '复习任务',
                              value: preview.taskCount,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: canExport ? _doExport : null,
                      child: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('导出并分享'),
                    ),
                    if (preview != null && preview.totalCount == 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '暂无数据可导出',
                        style: AppTypography.bodySecondary.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySecondary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
