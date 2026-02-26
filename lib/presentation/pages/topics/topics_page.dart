/// 文件用途：主题管理页（TopicsPage），用于主题列表展示与 CRUD（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/topics_provider.dart';
import '../../widgets/glass_card.dart';
import '../../../domain/usecases/manage_topic_usecase.dart';

class TopicsPage extends ConsumerWidget {
  /// 主题管理页。
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topicsProvider);
    final notifier = ref.read(topicsProvider.notifier);

    Future<void> createOrEdit({int? topicId}) async {
      final editing = topicId != null;
      final current = editing
          ? state.overviews.firstWhere((e) => e.topic.id == topicId).topic
          : null;
      final nameController = TextEditingController(text: current?.name ?? '');
      final descController = TextEditingController(
        text: current?.description ?? '',
      );

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(editing ? '编辑主题' : '新建主题'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '主题名称（必填）'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '主题描述（选填）'),
              ),
            ],
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
        ),
      );
      if (!context.mounted) return;
      if (ok != true) return;

      final name = nameController.text.trim();
      final desc = descController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('主题名称不能为空')),
        );
        return;
      }

      try {
        if (!editing) {
          await notifier.create(
            TopicParams(name: name, description: desc.isEmpty ? null : desc),
          );
        } else {
          await notifier.update(
            current!,
            TopicParams(name: name, description: desc.isEmpty ? null : desc),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题管理'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => notifier.load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '新建',
            onPressed: state.isLoading ? null : () => createOrEdit(),
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
                    : state.overviews.isEmpty
                        ? const _EmptyHint()
                        : ListView.separated(
                            itemCount: state.overviews.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final overview = state.overviews[index];
                              final topic = overview.topic;
                              final total = overview.totalCount;
                              final completed = overview.completedCount;
                              final progress = total == 0 ? 0.0 : completed / total;
                              return GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('🗂️', style: TextStyle(fontSize: 20)),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              topic.name,
                                              style: AppTypography.h2,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        '${overview.itemCount} 条内容   $completed/$total 完成',
                                        style: AppTypography.bodySecondary,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 8,
                                          backgroundColor: AppColors.glassBorder,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        children: [
                                          FilledButton(
                                            onPressed: () => context.push('/topics/${topic.id}'),
                                            child: const Text('查看'),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          OutlinedButton(
                                            onPressed: () => createOrEdit(topicId: topic.id),
                                            child: const Text('编辑'),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          TextButton(
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('删除主题'),
                                                  content: Text('确定删除「${topic.name}」吗？删除后仅解除关联，不删除学习内容。'),
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
                                                ),
                                              );
                                              if (ok != true) return;
                                              try {
                                                await notifier.delete(topic.id!);
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('删除失败：$e')),
                                                );
                                              }
                                            },
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      ),
                                    ],
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
    return const Center(
      child: Text(
        '还没有主题\n点击右上角 + 新建一个吧',
        style: AppTypography.bodySecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}
