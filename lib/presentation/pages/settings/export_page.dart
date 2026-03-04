/// 文件用途：数据导出页面（F8），支持 JSON/CSV 导出并通过系统分享。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isStatsExporting = false;
  bool _isPreviewLoading = true;
  ExportPreview? _preview;
  String? _error;
  int _statsYear = DateTime.now().year;

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

  Future<void> _doExportStatisticsCsv() async {
    setState(() {
      _isStatsExporting = true;
      _error = null;
    });

    try {
      final fileName = 'yike_statistics_$_statsYear.csv';

      // 桌面端：弹保存对话框；移动端：写入临时文件后分享。
      final isDesktop =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux);

      String? outputPath;
      if (isDesktop) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: '导出统计数据（CSV）',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['csv'],
        );
        if (outputPath == null || outputPath.trim().isEmpty) {
          // 用户取消保存。
          return;
        }
      }

      final result = await ref.read(exportStatisticsCsvUseCaseProvider).execute(
            year: _statsYear,
            outputPath: outputPath,
          );

      if (isDesktop) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导出：${result.file.path}')),
          );
        }
      } else {
        await Share.shareXFiles(
          [XFile(result.file.path)],
          text: '忆刻统计数据导出（$_statsYear）',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '导出成功：${result.fileName}（${_formatBytes(result.bytes)}）',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('统计导出失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStatsExporting = false);
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
                    Text('导出格式', style: AppTypography.h2(context)),
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
                      style: AppTypography.bodySecondary(context),
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
                    Text('导出内容', style: AppTypography.h2(context)),
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
                      style: AppTypography.bodySecondary(context),
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
                    Text('统计导出（CSV）', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '导出按天聚合的完成数/跳过数/待复习数与完成率，适合做长期分析。',
                      style: AppTypography.bodySecondary(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            // Flutter 3.33+：value 已废弃，改用 initialValue 表达“初始选中值”。
                            initialValue: _statsYear,
                            decoration: const InputDecoration(
                              labelText: '导出年份',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (
                                var y = DateTime.now().year;
                                y >= (DateTime.now().year - 10).clamp(2000, 9999);
                                y--
                              )
                                DropdownMenuItem(value: y, child: Text('$y')),
                            ],
                            onChanged: _isStatsExporting
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() => _statsYear = v);
                                  },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _isStatsExporting
                              ? null
                              : _doExportStatisticsCsv,
                          icon: _isStatsExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: const Text('导出'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '编码：UTF-8 无 BOM；分隔符：逗号。',
                      style: AppTypography.bodySecondary(context),
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
                    Text('数据预览', style: AppTypography.h2(context)),
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
                      Text('暂无数据', style: AppTypography.bodySecondary(context))
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
                        style: AppTypography.bodySecondary(context),
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
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySecondary(context)),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
