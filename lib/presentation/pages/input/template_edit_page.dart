/// 文件用途：模板编辑页（TemplateEditPage），用于新建/编辑模板并展示占位符替换预览（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
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
  late final TextEditingController _noteController;
  late final TextEditingController _tagsController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _titleController = TextEditingController(text: t?.titlePattern ?? '');
    _noteController = TextEditingController(text: t?.notePattern ?? '');
    _tagsController = TextEditingController(text: (t?.tags ?? const []).join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _noteController.dispose();
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
    return TemplateParams(
      name: _nameController.text.trim(),
      titlePattern: _titleController.text.trim(),
      notePattern: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tags: _parseTags(_tagsController.text),
      sortOrder: widget.template?.sortOrder ?? 0,
    );
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
                onPressed: () => Navigator.of(context).pop(_DupAction.overwrite),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('覆盖失败：$e2')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useCase = ref.read(manageTemplateUseCaseProvider);
    final preview = useCase.applyTemplate(
      LearningTemplateEntity(
        id: widget.template?.id,
        name: _nameController.text.trim().isEmpty ? '预览' : _nameController.text.trim(),
        titlePattern: _titleController.text,
        notePattern: _noteController.text,
        tags: _parseTags(_tagsController.text),
        sortOrder: widget.template?.sortOrder ?? 0,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        updatedAt: widget.template?.updatedAt,
      ),
      now: DateTime(2026, 2, 26),
    );

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
              const Text('模板名称', style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                maxLength: 30,
                decoration: const InputDecoration(hintText: '例如：每日单词复习'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return '请输入模板名称';
                  if (value.length > 30) return '模板名称最多 30 字';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('标题模板', style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                decoration: const InputDecoration(hintText: '例如：英语单词 {date}'),
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
                style: AppTypography.bodySecondary.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('替换预览', style: AppTypography.bodySecondary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(preview['title'] ?? ''),
                      if ((preview['note'] ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(preview['note'] ?? ''),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('备注模板', style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(hintText: '可选，例如：今日复习第 {weekday}'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('默认标签', style: AppTypography.bodySecondary),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(hintText: '例如：英语, 单词'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DupAction { overwrite, rename }
