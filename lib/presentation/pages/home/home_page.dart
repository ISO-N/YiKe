/// 文件用途：首页（今日复习任务），展示今日/逾期任务并支持完成、跳过与批量操作。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../providers/home_tasks_provider.dart';

class HomePage extends ConsumerWidget {
  /// 首页（今日复习）。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeTasksProvider);
    final notifier = ref.read(homeTasksProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.todayReview),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: state.isLoading ? null : () => notifier.load(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: () => notifier.toggleSelectionMode(),
            child: Text(state.isSelectionMode ? '完成' : '批量'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/input'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.input),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6FFFB),
              Color(0xFFF0FDFA),
              Color(0xFFFFF7ED),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _ProgressCard(
                  completed: state.completedCount,
                  total: state.totalCount,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.errorMessage != null) ...[
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        '加载失败：${state.errorMessage}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (state.isLoading) ...[
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                ] else ...[
                  if (state.overduePending.isNotEmpty) ...[
                    _SectionHeader(
                      title: '逾期任务',
                      subtitle: '优先处理红色逾期任务，避免堆积',
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...state.overduePending.map(
                      (t) => _TaskCard(
                        taskId: t.taskId,
                        title: t.title,
                        tags: t.tags,
                        isOverdue: true,
                        selectionMode: state.isSelectionMode,
                        selected: state.selectedTaskIds.contains(t.taskId),
                        onToggleSelected: () => notifier.toggleSelected(t.taskId),
                        onComplete: () => notifier.completeTask(t.taskId),
                        onSkip: () => notifier.skipTask(t.taskId),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _SectionHeader(
                    title: '今日待复习',
                    subtitle: state.todayPending.isEmpty ? '今天没有待复习任务' : null,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.todayPending.isEmpty && state.overduePending.isEmpty)
                    const _EmptyState()
                  else if (state.todayPending.isEmpty)
                    const _EmptySectionHint(text: AppStrings.emptyTodayTasks)
                  else
                    ...state.todayPending.map(
                      (t) => _TaskCard(
                        taskId: t.taskId,
                        title: t.title,
                        tags: t.tags,
                        isOverdue: false,
                        selectionMode: state.isSelectionMode,
                        selected: state.selectedTaskIds.contains(t.taskId),
                        onToggleSelected: () => notifier.toggleSelected(t.taskId),
                        onComplete: () => notifier.completeTask(t.taskId),
                        onSkip: () => notifier.skipTask(t.taskId),
                      ),
                    ),
                  const SizedBox(height: 96),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: state.isSelectionMode
          ? _BatchActionBar(
              selectedCount: state.selectedTaskIds.length,
              onCompleteSelected: state.selectedTaskIds.isEmpty ? null : notifier.completeSelected,
              onSkipSelected: state.selectedTaskIds.isEmpty ? null : notifier.skipSelected,
            )
          : null,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日进度', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$completed/$total',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, required this.color});

  final String title;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.h2),
        if (subtitle != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              subtitle!,
              style: AppTypography.bodySecondary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.taskId,
    required this.title,
    required this.tags,
    required this.isOverdue,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelected,
    required this.onComplete,
    required this.onSkip,
  });

  final int taskId;
  final String title;
  final List<String> tags;
  final bool isOverdue;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final borderColor = isOverdue ? AppColors.warning : AppColors.glassBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onToggleSelected(),
                    ),
                  )
                else
                  Icon(
                    isOverdue ? Icons.error_outline : Icons.circle_outlined,
                    color: isOverdue ? AppColors.warning : AppColors.textSecondary,
                    size: 22,
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags
                              .take(3)
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: Text(
                                    t,
                                    style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (!selectionMode)
                  Column(
                    children: [
                      IconButton(
                        tooltip: isOverdue ? '补做' : '完成',
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle_outline),
                        color: AppColors.success,
                      ),
                      IconButton(
                        tooltip: '跳过',
                        onPressed: onSkip,
                        icon: const Icon(Icons.not_interested_outlined),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchActionBar extends StatelessWidget {
  const _BatchActionBar({
    required this.selectedCount,
    required this.onCompleteSelected,
    required this.onSkipSelected,
  });

  final int selectedCount;
  final VoidCallback? onCompleteSelected;
  final VoidCallback? onSkipSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已选择 $selectedCount 项',
                    style: AppTypography.bodySecondary,
                  ),
                ),
                FilledButton(
                  onPressed: onCompleteSelected,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('完成所选'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: onSkipSelected,
                  child: const Text('跳过所选'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: const [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            SizedBox(height: AppSpacing.md),
            Text(AppStrings.emptyTodayTasks, style: AppTypography.bodySecondary, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        text,
        style: AppTypography.bodySecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}
