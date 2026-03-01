/// 文件用途：学习内容详情页（v3.1 F14.1 搜索跳转），展示标题/备注/标签与学习日期等信息。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/learning_item_detail_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

/// 学习内容详情页。
class LearningItemDetailPage extends ConsumerWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [itemId] 学习内容 ID
  const LearningItemDetailPage({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(learningItemDetailProvider(itemId));
    return Scaffold(
      appBar: AppBar(title: const Text('学习内容详情')),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '加载失败：$e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              data: (item) {
                if (item == null) {
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        '该学习内容不存在或已被删除',
                        style: AppTypography.bodySecondary(context),
                      ),
                    ),
                  );
                }

                final subtasks = item.subtasks;
                final description =
                    (item.item.description ?? '').trim().isNotEmpty
                        ? item.item.description!.trim()
                        : (item.item.note ?? '').trim();

                return ListView(
                  children: [
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('标题', style: AppTypography.h2(context)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.item.title,
                              style: AppTypography.body(
                                context,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('描述', style: AppTypography.h2(context)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              description.isEmpty ? '（无）' : description,
                              style: AppTypography.bodySecondary(context),
                            ),
                            if (subtasks.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text('子任务', style: AppTypography.h2(context)),
                              const SizedBox(height: AppSpacing.sm),
                              ...subtasks.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• '),
                                      Expanded(
                                        child: Text(
                                          s.content,
                                          style: AppTypography.bodySecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                            Text('信息', style: AppTypography.h2(context)),
                            const SizedBox(height: AppSpacing.md),
                            _InfoRow(
                              label: '学习日期',
                              value: YikeDateUtils.formatYmd(
                                item.item.learningDate,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: '创建时间',
                              value: item.item.createdAt.toIso8601String(),
                            ),
                            if (item.item.updatedAt != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: '更新时间',
                                value: item.item.updatedAt!.toIso8601String(),
                              ),
                            ],
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: '数据类型',
                              value:
                                  item.item.isMockData
                                      ? 'Mock（仅调试）'
                                      : '真实数据',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (item.item.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('标签', style: AppTypography.h2(context)),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: item.item.tags
                                    .take(20)
                                    .map(
                                      (t) => Chip(
                                        label: Text(t),
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 96),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(label, style: AppTypography.bodySecondary(context)),
        ),
        Expanded(child: Text(value, style: AppTypography.body(context))),
      ],
    );
  }
}
