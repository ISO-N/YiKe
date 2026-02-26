/// 文件用途：批量导入预览页（ImportPreviewPage），支持 TXT/CSV/Markdown 解析、编辑与导入到录入草稿（F1.1）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/file_parser.dart';
import '../../widgets/glass_card.dart';
import 'draft_learning_item.dart';

class ImportPreviewPage extends ConsumerStatefulWidget {
  /// 批量导入预览页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const ImportPreviewPage({super.key});

  @override
  ConsumerState<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends ConsumerState<ImportPreviewPage> {
  bool _loading = false;
  String? _filePath;
  String? _error;
  List<_PreviewItem> _items = const [];

  @override
  void initState() {
    super.initState();
    // v2.1：进入页面后提示用户选择文件。
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFile());
  }

  Future<void> _pickFile() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'csv', 'md', 'markdown'],
      );
      if (!mounted) return;
      final path = result?.files.single.path;
      if (path == null) {
        setState(() => _loading = false);
        return;
      }

      final parsed = await FileParser.parseFile(path);
      if (!mounted) return;
      if (parsed.isEmpty) {
        setState(() {
          _loading = false;
          _filePath = path;
          _items = const [];
          _error = '未识别到有效内容，请检查文件格式或内容是否为空。';
        });
        return;
      }

      setState(() {
        _loading = false;
        _filePath = path;
        _items = parsed
            .map((e) => _PreviewItem(item: e, selected: e.isValid))
            .toList();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '解析失败：$e';
      });
    }
  }

  Future<void> _editItem(int index) async {
    final current = _items[index];
    final titleController = TextEditingController(text: current.item.title);
    final noteController = TextEditingController(text: current.item.note ?? '');
    final tagsController = TextEditingController(
      text: current.item.tags.join(', '),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑导入条目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '标题（必填）'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '备注（选填）'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(labelText: '标签（选填，用逗号分隔）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (ok != true) return;

    final title = titleController.text.trim();
    final note = noteController.text.trim();
    final tags = tagsController.text
        .split(RegExp(r'[，,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _items = [
        ..._items.take(index),
        current.copyWith(
          item: current.item.copyWith(
            title: title,
            note: note.isEmpty ? null : note,
            tags: tags,
            errorMessage: title.isEmpty ? '标题为空' : null,
          ),
          // 编辑后：仅当条目有效才默认勾选。
          selected: title.isNotEmpty,
        ),
        ..._items.skip(index + 1),
      ];
    });
  }

  Future<void> _confirmImport() async {
    final selected = _items
        .where((e) => e.selected)
        .map((e) => e.item)
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少选择一条有效内容')));
      return;
    }

    final duplicates = _findDuplicateTitles(selected);
    if (duplicates.isNotEmpty) {
      final action = await _askDuplicateAction(duplicates.length);
      if (!mounted) return;
      if (action == null) return;
      final resolved = _resolveDuplicates(selected, action);
      Navigator.of(context).pop(resolved.map(_toDraft).toList());
      return;
    }

    Navigator.of(context).pop(selected.map(_toDraft).toList());
  }

  DraftLearningItem _toDraft(ParsedItem e) {
    return DraftLearningItem(title: e.title, note: e.note, tags: e.tags);
  }

  Set<String> _findDuplicateTitles(List<ParsedItem> items) {
    final seen = <String>{};
    final dup = <String>{};
    for (final item in items) {
      final title = item.title.trim();
      if (title.isEmpty) continue;
      if (!seen.add(title)) dup.add(title);
    }
    return dup;
  }

  Future<_DuplicateAction?> _askDuplicateAction(int count) {
    return showDialog<_DuplicateAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('检测到重复标题'),
          content: Text('当前选中内容中存在 $count 个重复标题，是否覆盖或跳过重复项？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(_DuplicateAction.skip),
              child: const Text('跳过重复'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_DuplicateAction.overwrite),
              child: const Text('覆盖重复'),
            ),
          ],
        );
      },
    );
  }

  List<ParsedItem> _resolveDuplicates(
    List<ParsedItem> items,
    _DuplicateAction action,
  ) {
    if (action == _DuplicateAction.skip) {
      // 跳过重复：保留第一次出现。
      final seen = <String>{};
      final list = <ParsedItem>[];
      for (final item in items) {
        final title = item.title.trim();
        if (title.isEmpty) continue;
        if (seen.add(title)) list.add(item);
      }
      return list;
    }

    // 覆盖重复：保留最后一次出现。
    final map = <String, ParsedItem>{};
    for (final item in items) {
      final title = item.title.trim();
      if (title.isEmpty) continue;
      map[title] = item;
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((e) => e.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('批量导入'),
        actions: [
          IconButton(
            tooltip: '选择文件',
            onPressed: _loading ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
          ),
          TextButton(
            onPressed: _loading ? null : _confirmImport,
            child: const Text('导入'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('导入预览', style: AppTypography.h2(context)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _filePath == null
                            ? '请选择 TXT/CSV/Markdown 文件进行导入'
                            : '文件：${_filePath!.split(RegExp(r'[\\/]')).last}',
                        style: AppTypography.bodySecondary(context),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          style: AppTypography.bodySecondary(
                            context,
                          ).copyWith(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '已选 $selectedCount 条 / 共 ${_items.length} 条',
                        style: AppTypography.bodySecondary(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? const _EmptyHint()
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          final hasError = it.item.errorMessage != null;
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final normalBorderColor = isDark
                              ? AppColors.darkGlassBorder
                              : AppColors.glassBorder;
                          final borderColor = hasError
                              ? AppColors.error
                              : normalBorderColor;
                          return GlassCard(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: it.selected,
                                  onChanged: hasError
                                      ? null
                                      : (v) => setState(
                                          () => _items = [
                                            ..._items.take(index),
                                            it.copyWith(selected: v ?? false),
                                            ..._items.skip(index + 1),
                                          ],
                                        ),
                                ),
                                title: Text(
                                  it.item.title.trim().isEmpty
                                      ? '（无标题）'
                                      : it.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: hasError
                                    ? Text(
                                        it.item.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      )
                                    : (it.item.note == null ||
                                          it.item.note!.trim().isEmpty)
                                    ? Text(
                                        '无备注',
                                        style: AppTypography.bodySecondary(
                                          context,
                                        ),
                                      )
                                    : Text(
                                        it.item.note!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: '编辑',
                                      onPressed: () => _editItem(index),
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      tooltip: '删除',
                                      onPressed: () => setState(() {
                                        _items = [
                                          ..._items.take(index),
                                          ..._items.skip(index + 1),
                                        ];
                                      }),
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                                onTap: () => _editItem(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '暂无导入内容\n点击右上角文件按钮选择文件',
        style: AppTypography.bodySecondary(context),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PreviewItem {
  const _PreviewItem({required this.item, required this.selected});

  final ParsedItem item;
  final bool selected;

  _PreviewItem copyWith({ParsedItem? item, bool? selected}) {
    return _PreviewItem(
      item: item ?? this.item,
      selected: selected ?? this.selected,
    );
  }
}

enum _DuplicateAction { skip, overwrite }
