/// 文件用途：模板排序页（TemplateSortPage），用于拖拽排序并持久化 sortOrder（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/learning_template.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/glass_card.dart';

class TemplateSortPage extends ConsumerStatefulWidget {
  /// 模板排序页。
  const TemplateSortPage({super.key, required this.templates});

  final List<LearningTemplateEntity> templates;

  @override
  ConsumerState<TemplateSortPage> createState() => _TemplateSortPageState();
}

class _TemplateSortPageState extends ConsumerState<TemplateSortPage> {
  late List<LearningTemplateEntity> _ordered;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ordered = [...widget.templates];
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(templatesProvider.notifier).reorder(_ordered);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存排序失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模板排序'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const Text('保存中...') : const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _ordered.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _ordered.removeAt(oldIndex);
              _ordered.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final t = _ordered[index];
            return Padding(
              key: ValueKey(t.id ?? index),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text(t.titlePattern, maxLines: 1),
                  trailing: const Icon(Icons.drag_handle),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

