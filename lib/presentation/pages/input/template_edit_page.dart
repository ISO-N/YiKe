/// 文件用途：模板编辑页（TemplateEditPage），用于新建/编辑模板并展示占位符替换预览（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/note_migration_parser.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/learning_template.dart';
import '../../../domain/usecases/manage_template_usecase.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/glass_card.dart';

class TemplateEditPage extends ConsumerStatefulWidget {
  /// 模板编辑页（新建/编辑）。
  const TemplateEditPage({super.key, this.template});

  final LearningTemplateEntity? template;

  @override
  ConsumerState<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends ConsumerState<TemplateEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  final List<_SubtaskController> _subtasks = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _titleController = TextEditingController(text: t?.titlePattern ?? '');
    final parsed = NoteMigrationParser.parse(t?.notePattern ?? '');
    _descriptionController = TextEditingController(text: parsed.description ?? '');
    for (final s in parsed.subtasks) {
      _subtasks.add(
        _SubtaskController(
          key: _newSubtaskKey(),
          controller: TextEditingController(text: s),
        ),
      );
    }
    _tagsController = TextEditingController(
      text: (t?.tags ?? const []).join(', '),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    for (final s in _subtasks) {
      s.dispose();
    }
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[，,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  TemplateParams _params() {
    final notePattern = _buildTemplateNotePattern(
      description: _descriptionController.text,
      subtasks: _subtasks.map((e) => e.controller.text).toList(),
    );
    return TemplateParams(
      name: _nameController.text.trim(),
      titlePattern: _titleController.text.trim(),
      // v2.6：模板编辑 UI 切换为“描述 + 子任务”，存储层仍沿用 notePattern（渐进式迁移）。
      notePattern: notePattern,
      tags: _parseTags(_tagsController.text),
      sortOrder: widget.template?.sortOrder ?? 0,
    );
  }

  String _newSubtaskKey() => 'subtask_${DateTime.now().microsecondsSinceEpoch}';

  void _addSubtask() {
    setState(() {
      _subtasks.add(
        _SubtaskController(
          key: _newSubtaskKey(),
          controller: TextEditingController(),
        ),
      );
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      final removed = _subtasks.removeAt(index);
      removed.dispose();
    });
  }

  /// 将“描述 + 子任务列表”拼接成模板的 notePattern（渐进式迁移）。
  ///
  /// 说明：
  /// - 模板表结构仍使用 notePattern 字段保存文本
  /// - 后续应用模板时会使用与迁移一致的解析规则拆回 description/subtasks
  String? _buildTemplateNotePattern({
    required String description,
    required List<String> subtasks,
  }) {
    final desc = description.trim();
    final list = subtasks.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final buffer = StringBuffer();
    if (desc.isNotEmpty) {
      buffer.writeln(desc);
    }
    if (list.isNotEmpty) {
      if (desc.isNotEmpty) buffer.writeln();
      for (final s in list) {
        buffer.writeln('- $s');
      }
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    final notifier = ref.read(templatesProvider.notifier);

    try {
      final params = _params();
      if (widget.template == null) {
        await notifier.create(params);
      } else {
        await notifier.update(widget.template!, params);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      // v2.1：模板名称重复时，允许用户选择覆盖或继续编辑改名。
      final message = e.toString();
      if (message.contains('模板名称已存在')) {
        final action = await showDialog<_DupAction>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('模板名称已存在'),
            content: const Text('是否覆盖同名模板？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(_DupAction.rename),
                child: const Text('重命名'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_DupAction.overwrite),
                child: const Text('覆盖'),
              ),
            ],
          ),
        );

        if (action == _DupAction.overwrite) {
          final list = ref.read(templatesProvider).templates;
          final target = list.firstWhere(
            (t) => t.name.trim() == _nameController.text.trim(),
            orElse: () => widget.template ?? list.first,
          );
          try {
            await notifier.update(target, _params());
            if (mounted) Navigator.of(context).pop();
          } catch (e2) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('覆盖失败：$e2')));
          }
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useCase = ref.read(manageTemplateUseCaseProvider);
    final notePattern = _buildTemplateNotePattern(
      description: _descriptionController.text,
      subtasks: _subtasks.map((e) => e.controller.text).toList(),
    );
    final preview = useCase.applyTemplate(
      LearningTemplateEntity(
        id: widget.template?.id,
        uuid: widget.template?.uuid ?? 'preview',
        name: _nameController.text.trim().isEmpty
            ? '预览'
            : _nameController.text.trim(),
        titlePattern: _titleController.text,
        notePattern: notePattern,
        tags: _parseTags(_tagsController.text),
        sortOrder: widget.template?.sortOrder ?? 0,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        updatedAt: widget.template?.updatedAt,
      ),
      now: DateTime(2026, 2, 26),
    );

    final previewParsed = NoteMigrationParser.parse(preview['note'] ?? '');
    final previewDesc = (previewParsed.description ?? '').trim();
    final previewSubtasks = previewParsed.subtasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? '新建模板' : '编辑模板'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const Text('保存中...') : const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('模板名称', style: AppTypography.bodySecondary(context)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                maxLength: 30,
                decoration: const InputDecoration(hintText: '例如：每日单词复习'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return '请输入模板名称';
                  if (value.length > 30) return '模板名称最多 30 字';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('标题模板', style: AppTypography.bodySecondary(context)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                decoration: const InputDecoration(hintText: '例如：英语单词 {date}'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return '请输入标题模板';
                  if (value.length > 50) return '标题模板最多 50 字';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '{date} → 2026-02-26，{day} → 2026-2-26，{weekday} → 周三',
                style: AppTypography.bodySecondary(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('替换预览', style: AppTypography.bodySecondary(context)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(preview['title'] ?? ''),
                      if (previewDesc.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text('描述：$previewDesc'),
                      ],
                      if (previewSubtasks.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '子任务：${previewSubtasks.take(3).join(' / ')}'
                          '${previewSubtasks.length > 3 ? '…' : ''}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('描述模板', style: AppTypography.bodySecondary(context)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '可选，例如：今日复习第 {weekday}',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('子任务模板', style: AppTypography.bodySecondary(context)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新增'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_subtasks.isEmpty)
                Text('（无）', style: AppTypography.bodySecondary(context))
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subtasks.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      var target = newIndex;
                      if (newIndex > oldIndex) target = newIndex - 1;
                      final moved = _subtasks.removeAt(oldIndex);
                      _subtasks.insert(target, moved);
                    });
                  },
                  itemBuilder: (context, index) {
                    final s = _subtasks[index];
                    return Padding(
                      key: ValueKey(s.key),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: s.controller,
                              decoration: const InputDecoration(
                                hintText: '输入子任务内容（支持占位符）',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: '删除',
                            onPressed: () => _removeSubtask(index),
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              Text('默认标签', style: AppTypography.bodySecondary(context)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(hintText: '例如：英语, 单词'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DupAction { overwrite, rename }

class _SubtaskController {
  _SubtaskController({required this.key, required this.controller});

  final String key;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}
