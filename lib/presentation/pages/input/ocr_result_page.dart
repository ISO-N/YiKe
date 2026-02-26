/// 文件用途：OCR 识别结果页（OcrResultPage），支持图片选择、识别结果编辑并添加到录入草稿（F1.4）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../di/providers.dart';
import '../../../domain/services/ocr_service.dart';
import '../../widgets/glass_card.dart';
import 'draft_learning_item.dart';

class OcrResultPage extends ConsumerStatefulWidget {
  /// OCR 结果页。
  ///
  /// 参数：
  /// - [imagePaths] 待识别图片路径（允许多张）
  const OcrResultPage({super.key, required this.imagePaths});

  final List<String> imagePaths;

  @override
  ConsumerState<OcrResultPage> createState() => _OcrResultPageState();
}

class _OcrResultPageState extends ConsumerState<OcrResultPage> {
  bool _loading = true;
  String? _error;
  final List<_OcrDraftControllers> _drafts = [];

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _runOcr() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final useCase = ref.read(ocrRecognitionUseCaseProvider);
      _drafts.clear();

      for (final path in widget.imagePaths) {
        final OcrResult result = await useCase.execute(path);
        final draft = _toDraft(result.text);
        _drafts.add(
          _OcrDraftControllers(
            imagePath: path,
            title: TextEditingController(text: draft.title),
            note: TextEditingController(text: draft.note ?? ''),
            tags: TextEditingController(text: draft.tags.join(', ')),
            confidence: result.confidence,
          ),
        );
        if (mounted) setState(() {});
      }

      if (_drafts.isEmpty) {
        setState(() {
          _loading = false;
          _error = '未识别到有效内容';
        });
        return;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  DraftLearningItem _toDraft(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trimRight())
        .toList();
    final first = lines.firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
    final idx = lines.indexOf(first);
    final note = (idx < 0 || idx + 1 >= lines.length)
        ? ''
        : lines.sublist(idx + 1).join('\n').trim();
    return DraftLearningItem(
      title: first.trim(),
      note: note.isEmpty ? null : note,
      tags: const [],
    );
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[，,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _removeAt(int index) {
    setState(() {
      final d = _drafts.removeAt(index);
      d.dispose();
    });
  }

  Future<void> _confirmAdd() async {
    if (_drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可添加的内容')),
      );
      return;
    }

    final drafts = <DraftLearningItem>[];
    final invalid = <int>[];
    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      final title = d.title.text.trim();
      final note = d.note.text.trim();
      if (title.isEmpty) {
        invalid.add(i + 1);
        continue;
      }
      drafts.add(
        DraftLearningItem(
          title: title,
          note: note.isEmpty ? null : note,
          tags: _parseTags(d.tags.text),
        ),
      );
    }

    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('第 ${invalid.join('、')} 项标题为空，请先补全')),
      );
      return;
    }

    Navigator.of(context).pop(drafts);
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.imagePaths.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(multi ? 'OCR 批量识别' : '拍照识别'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _confirmAdd,
            child: const Text('确认'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null)
                  ? GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          '识别失败：$_error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _drafts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        final d = _drafts[index];
                        return GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        multi ? '图片 ${index + 1}' : '图片预览',
                                        style: AppTypography.h2(context),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: '移除',
                                      onPressed: _drafts.length <= 1
                                          ? null
                                          : () => _removeAt(index),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.file(
                                      File(d.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '识别结果（可编辑）',
                                  style: AppTypography.bodySecondary(context),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  controller: d.title,
                                  decoration: const InputDecoration(
                                    labelText: '标题（必填）',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: d.note,
                                  minLines: 3,
                                  maxLines: 8,
                                  decoration: const InputDecoration(
                                    labelText: '备注（选填）',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: d.tags,
                                  decoration: const InputDecoration(
                                    labelText: '标签（选填，用逗号分隔）',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '置信度：${(d.confidence * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.bodySecondary(context),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FilledButton(
                                  onPressed: _confirmAdd,
                                  child: Text(multi ? '全部添加到录入' : '+ 添加到录入'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _OcrDraftControllers {
  _OcrDraftControllers({
    required this.imagePath,
    required this.title,
    required this.note,
    required this.tags,
    required this.confidence,
  });

  final String imagePath;
  final TextEditingController title;
  final TextEditingController note;
  final TextEditingController tags;
  final double confidence;

  void dispose() {
    title.dispose();
    note.dispose();
    tags.dispose();
  }
}
