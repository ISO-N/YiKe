/// 文件用途：录入页（学习内容录入），支持一次录入多条内容并自动生成复习计划。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../di/providers.dart';
import '../../../domain/usecases/create_learning_item_usecase.dart';
import '../../providers/home_tasks_provider.dart';
import '../../widgets/glass_card.dart';

class InputPage extends ConsumerStatefulWidget {
  /// 录入页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const InputPage({super.key});

  @override
  ConsumerState<InputPage> createState() => _InputPageState();
}

class _InputPageState extends ConsumerState<InputPage> {
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  final List<_DraftItemControllers> _items = [];
  late final Future<List<String>> _availableTagsFuture;

  @override
  void initState() {
    super.initState();
    // v1.0 MVP：默认提供一条输入项。
    _items.add(_DraftItemControllers());
    _availableTagsFuture = ref
        .read(learningItemRepositoryProvider)
        .getAllTags();
  }

  @override
  void dispose() {
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    try {
      final useCase = ref.read(createLearningItemUseCaseProvider);

      for (final c in _items) {
        final title = c.title.text.trim();
        final note = c.note.text.trim();
        final tags = _parseTags(c.tags.text);

        final params = CreateLearningItemParams(
          title: title,
          note: note.isEmpty ? null : note,
          tags: tags,
        );
        await useCase.execute(params);
      }

      // 刷新首页数据（同时会同步小组件）。
      await ref.read(homeTasksProvider.notifier).load();

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[，,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _addItem() {
    setState(() => _items.add(_DraftItemControllers()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录入'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _onSave,
            child: _saving ? const Text('保存中...') : const Text('保存'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('今天学了什么？', style: AppTypography.h2),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          '录入后会自动生成 5 次复习任务（+1/+2/+4/+7/+15 天）。',
                          style: AppTypography.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controllers = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '条目 ${index + 1}',
                                  style: AppTypography.h2,
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: '删除条目',
                                  onPressed: _saving
                                      ? null
                                      : () => _removeItem(index),
                                  icon: const Icon(Icons.delete_outline),
                                  color: _items.length <= 1
                                      ? AppColors.textSecondary
                                      : AppColors.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: controllers.title,
                              maxLength: 50,
                              decoration: const InputDecoration(
                                labelText: '标题（必填）',
                                hintText: '例如：Java 集合框架',
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return '请输入标题';
                                if (value.length > 50) return '标题最多 50 字';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: controllers.note,
                              minLines: 2,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: '备注（选填，v1.0 仅纯文本）',
                                hintText: '补充重点、易错点等',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: controllers.tags,
                              decoration: const InputDecoration(
                                labelText: '标签（选填，用逗号分隔）',
                                hintText: '例如：Java, 面试',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FutureBuilder<List<String>>(
                              future: _availableTagsFuture,
                              builder: (context, snapshot) {
                                final tags = snapshot.data ?? const <String>[];
                                if (tags.isEmpty) {
                                  return const Text(
                                    '还没有标签，创建一个吧',
                                    style: AppTypography.bodySecondary,
                                  );
                                }
                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: tags.take(12).map((t) {
                                    return ActionChip(
                                      label: Text(t),
                                      onPressed: _saving
                                          ? null
                                          : () =>
                                                _appendTag(controllers.tags, t),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('再添加一条'),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: ColoredBox(
                // v1.0 MVP：避免使用 withOpacity 的精度警告，改为 withAlpha。
                color: Colors.black.withAlpha((0.15 * 255).round()),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  void _appendTag(TextEditingController controller, String tag) {
    final current = _parseTags(controller.text);
    if (current.contains(tag)) return;
    current.add(tag);
    controller.text = current.join(', ');
  }
}

class _DraftItemControllers {
  _DraftItemControllers()
    : title = TextEditingController(),
      note = TextEditingController(),
      tags = TextEditingController();

  final TextEditingController title;
  final TextEditingController note;
  final TextEditingController tags;

  /// 释放控制器资源。
  void dispose() {
    title.dispose();
    note.dispose();
    tags.dispose();
  }
}
