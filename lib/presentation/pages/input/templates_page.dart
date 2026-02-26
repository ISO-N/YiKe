/// 文件用途：模板管理页（TemplatesPage），用于快速模板的查看/新建/编辑/删除与排序入口（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/glass_card.dart';
import 'template_edit_page.dart';
import 'template_sort_page.dart';

class TemplatesPage extends ConsumerWidget {
  /// 模板管理页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templatesProvider);
    final notifier = ref.read(templatesProvider.notifier);

    Future<void> openEdit({int? templateId}) async {
      final template = templateId == null
          ? null
          : state.templates.firstWhere((e) => e.id == templateId);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TemplateEditPage(template: template),
          fullscreenDialog: true,
        ),
      );
    }

    Future<void> openSort() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TemplateSortPage(templates: state.templates),
          fullscreenDialog: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => notifier.load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '排序',
            onPressed: state.isLoading ? null : openSort,
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            tooltip: '新建',
            onPressed: state.isLoading ? null : () => openEdit(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (state.errorMessage != null) ...[
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      '加载失败：${state.errorMessage}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.templates.isEmpty
                        ? const _EmptyHint()
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: AppSpacing.md,
                                  crossAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 1.05,
                                ),
                            itemCount: state.templates.length,
                            itemBuilder: (context, index) {
                              final t = state.templates[index];
                              return _TemplateCard(
                                name: t.name,
                                preview: t.titlePattern,
                                tagCount: t.tags.length,
                                onEdit: () => openEdit(templateId: t.id),
                                onDelete: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('删除模板'),
                                      content: Text('确定删除「${t.name}」吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('取消'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;
                                  try {
                                    await notifier.delete(t.id!);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('删除失败：$e')),
                                    );
                                  }
                                },
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.name,
    required this.preview,
    required this.tagCount,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final String preview;
  final int tagCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋', style: TextStyle(fontSize: 22)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              style: AppTypography.h2.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              preview,
              style: AppTypography.bodySecondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '🏷️ $tagCount',
                  style: AppTypography.bodySecondary,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 20),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '还没有模板\n点击右上角 + 新建一个吧',
        style: AppTypography.bodySecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

