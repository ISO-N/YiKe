/// 文件用途：任务中心页面（全量任务时间线，支持筛选、分组与游标分页）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/task_filter_provider.dart';
import '../../providers/task_hub_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/task_filter_bar.dart';

/// 任务中心页面。
class TaskHubPage extends ConsumerStatefulWidget {
  /// 构造函数。
  const TaskHubPage({super.key});

  @override
  ConsumerState<TaskHubPage> createState() => _TaskHubPageState();
}

class _TaskHubPageState extends ConsumerState<TaskHubPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 游标分页：接近底部时自动加载下一页，避免 offset 分页的性能问题。
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(taskHubProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskHubProvider);
    final notifier = ref.read(taskHubProvider.notifier);

    void showSnack(String text) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }

    void runAction(Future<void> Function() action, {required String ok}) {
      action()
          .then((_) => showSnack(ok))
          .catchError((e) => showSnack('操作失败：$e'));
    }

    Future<void> confirmUndo(int taskId) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('撤销任务状态？'),
            content: const Text(
              '该任务将恢复为待复习状态。此操作可能影响今日统计和连续打卡天数，是否确认撤销？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认撤销'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
      runAction(() => notifier.undoTaskStatus(taskId), ok: '已撤销');
    }

    final grouped = <DateTime, List<_TaskTimelineItem>>{};
    for (final item in state.items) {
      final day = YikeDateUtils.atStartOfDay(item.occurredAt);
      grouped.putIfAbsent(day, () => []).add(
        _TaskTimelineItem(
          taskId: item.task.taskId,
          title: item.task.title,
          note: item.task.note,
          tags: item.task.tags,
          reviewRound: item.task.reviewRound,
          scheduledDate: item.task.scheduledDate,
          status: item.task.status,
          completedAt: item.task.completedAt,
          skippedAt: item.task.skippedAt,
          occurredAt: item.occurredAt,
        ),
      );
    }

    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.taskHubTitle)),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TaskFilterBar(
                  filter: state.filter,
                  counts: state.counts,
                  onChanged: (next) => notifier.setFilter(next),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.errorMessage != null) ...[
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        '加载失败：${state.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (state.isLoading && state.items.isEmpty) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (state.items.isEmpty) ...[
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        '暂无任务',
                        style: AppTypography.bodySecondary(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ] else ...[
                  for (final day in sortedDays) ...[
                    _GroupHeader(label: _groupLabel(day)),
                    const SizedBox(height: AppSpacing.sm),
                    for (final item in grouped[day]!) ...[
                      _TaskTimelineCard(
                        item: item,
                        expanded: state.expandedTaskIds.contains(item.taskId),
                        onToggleExpanded: () => notifier.toggleExpanded(item.taskId),
                        onComplete:
                            item.status == ReviewTaskStatus.pending
                                ? () => runAction(
                                  () => notifier.completeTask(item.taskId),
                                  ok: '已完成',
                                )
                                : null,
                        onSkip:
                            item.status == ReviewTaskStatus.pending
                                ? () => runAction(
                                  () => notifier.skipTask(item.taskId),
                                  ok: '已跳过',
                                )
                                : null,
                        onUndo:
                            item.status == ReviewTaskStatus.pending
                                ? null
                                : () => confirmUndo(item.taskId),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (state.isLoadingMore)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.nextCursor == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '已加载全部任务',
                        style: AppTypography.bodySecondary(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 48),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _groupLabel(DateTime day) {
    // 日期分组标题语义：今天/昨天/具体日期（M月d日）。
    final today = YikeDateUtils.atStartOfDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    if (YikeDateUtils.isSameDay(day, today)) return '今天';
    if (YikeDateUtils.isSameDay(day, yesterday)) return '昨天';
    return DateFormat('M月d日').format(day);
  }
}

/// 日期分组标题。
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTypography.h2(context));
  }
}

/// 时间线条目（UI 侧使用的轻量结构，避免在构建阶段频繁拆解实体）。
class _TaskTimelineItem {
  const _TaskTimelineItem({
    required this.taskId,
    required this.title,
    required this.note,
    required this.tags,
    required this.reviewRound,
    required this.scheduledDate,
    required this.status,
    required this.completedAt,
    required this.skippedAt,
    required this.occurredAt,
  });

  final int taskId;
  final String title;
  final String? note;
  final List<String> tags;
  final int reviewRound;
  final DateTime scheduledDate;
  final ReviewTaskStatus status;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final DateTime occurredAt;
}

/// 时间线任务卡片：点击展开操作区（完成/跳过/撤销）。
class _TaskTimelineCard extends StatelessWidget {
  const _TaskTimelineCard({
    required this.item,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onComplete,
    required this.onSkip,
    required this.onUndo,
  });

  final _TaskTimelineItem item;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : Colors.black;
    final secondary = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final tag = switch (item.status) {
      ReviewTaskStatus.done => const _StatusTag(label: '已完成', color: Colors.green),
      ReviewTaskStatus.skipped => const _StatusTag(label: '已跳过', color: Colors.orange),
      ReviewTaskStatus.pending => null,
    };

    final subtitle = _subtitleText(context);

    return InkWell(
      onTap: onToggleExpanded,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.title}（第${item.reviewRound}次）',
                          style: AppTypography.body(
                            context,
                          ).copyWith(fontWeight: FontWeight.w700, color: primary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle, style: AppTypography.bodySecondary(context)),
                      ],
                    ),
                  ),
                  if (tag != null) tag,
                ],
              ),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.tags
                      .take(5)
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(
                              24,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(80),
                            ),
                          ),
                          child: Text(
                            t,
                            style: AppTypography.bodySecondary(
                              context,
                            ).copyWith(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              AnimatedCrossFade(
                // 交互要求：点击卡片展开/收起操作区。
                crossFadeState:
                    expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 160),
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((item.note ?? '').trim().isNotEmpty) ...[
                        Text('备注', style: AppTypography.h2(context).copyWith(fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(item.note!.trim(), style: AppTypography.bodySecondary(context)),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Row(
                        children: [
                          if (onComplete != null)
                            FilledButton(
                              onPressed: onComplete,
                              child: const Text('完成'),
                            ),
                          if (onComplete != null) const SizedBox(width: AppSpacing.sm),
                          if (onSkip != null)
                            OutlinedButton(
                              onPressed: onSkip,
                              child: const Text('跳过'),
                            ),
                          if (onUndo != null)
                            OutlinedButton(
                              onPressed: onUndo,
                              child: const Text('撤销'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expanded ? '点击卡片可收起操作区' : '',
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleText(BuildContext context) {
    switch (item.status) {
      case ReviewTaskStatus.pending:
        return '待复习';
      case ReviewTaskStatus.done:
        final time = item.completedAt;
        if (time == null) return '已完成';
        return '完成于 ${TimeOfDay.fromDateTime(time).format(context)}';
      case ReviewTaskStatus.skipped:
        final time = item.skippedAt;
        if (time == null) return '已跳过';
        return '跳过于 ${TimeOfDay.fromDateTime(time).format(context)}';
    }
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySecondary(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
