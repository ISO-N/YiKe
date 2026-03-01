/// 文件用途：任务中心时间线列表（供任务中心页与首页 tab=all 复用）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/review_task.dart';
import '../../../providers/task_hub_provider.dart';
import '../../../widgets/glass_card.dart';

/// 任务中心时间线列表（不包含筛选栏与滚动容器）。
///
/// 设计说明：
/// - 该组件只负责“列表内容”渲染与卡片交互（展开/完成/跳过/撤销/详情）。
/// - 滚动、下拉刷新、游标分页触发（loadMore）由上层页面负责。
class TaskHubTimelineList extends StatelessWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [state] 任务中心状态。
  /// - [notifier] 任务中心 Notifier（用于执行操作与更新展开状态）。
  /// 返回值：Widget。
  /// 异常：无。
  const TaskHubTimelineList({
    super.key,
    required this.state,
    required this.notifier,
  });

  final TaskHubState state;
  final TaskHubNotifier notifier;

  @override
  Widget build(BuildContext context) {
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
            content: const Text('该任务将恢复为待复习状态，是否确认撤销？'),
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
          learningItemId: item.task.learningItemId,
          title: item.task.title,
          description: item.task.description,
          legacyNote: item.task.note,
          subtaskCount: item.task.subtaskCount,
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

    // 发生时间正序：日期分组按从早到晚展示。
    final sortedDays = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                onOpenDetail: () => context.push(
                  '/tasks/detail/${item.learningItemId}',
                ),
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
    required this.learningItemId,
    required this.title,
    required this.description,
    required this.legacyNote,
    required this.subtaskCount,
    required this.tags,
    required this.reviewRound,
    required this.scheduledDate,
    required this.status,
    required this.completedAt,
    required this.skippedAt,
    required this.occurredAt,
  });

  final int taskId;
  final int learningItemId;
  final String title;
  final String? description;
  final String? legacyNote;
  final int subtaskCount;
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
    required this.onOpenDetail,
  });

  final _TaskTimelineItem item;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onUndo;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : Colors.black;
    final secondary = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final tag = switch (item.status) {
      ReviewTaskStatus.done => const _StatusTag(label: '已完成', color: Colors.green),
      ReviewTaskStatus.skipped =>
        const _StatusTag(label: '已跳过', color: Colors.orange),
      ReviewTaskStatus.pending => null,
    };

    final subtitle = _subtitleText(context);
    final info = _infoText();
    final detailLabel = _expandedDetailLabel();
    final detailText = _expandedDetailText();

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
                        if (info != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            info,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySecondary(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  tag ?? const SizedBox.shrink(),
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
                    expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 160),
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detailLabel != null && detailText != null) ...[
                        Text(
                          detailLabel,
                          style: AppTypography.h2(context).copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detailText,
                          style: AppTypography.bodySecondary(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Row(
                        children: [
                          if (onComplete != null)
                            FilledButton(
                              onPressed: onComplete,
                              child: const Text('完成'),
                            ),
                          if (onComplete != null)
                            const SizedBox(width: AppSpacing.sm),
                          if (onSkip != null)
                            OutlinedButton(
                              onPressed: onSkip,
                              child: const Text('跳过'),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: onOpenDetail,
                            child: const Text('详情'),
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
    return switch (item.status) {
      ReviewTaskStatus.pending => '待复习',
      ReviewTaskStatus.done =>
        item.completedAt == null
            ? '已完成'
            : '完成于 ${TimeOfDay.fromDateTime(item.completedAt!).format(context)}',
      ReviewTaskStatus.skipped =>
        item.skippedAt == null
            ? '已跳过'
            : '跳过于 ${TimeOfDay.fromDateTime(item.skippedAt!).format(context)}',
    };
  }

  /// 生成时间线卡片的信息摘要（v2.6：description 优先，其次子任务数量，最后 fallback 到旧 note）。
  String? _infoText() {
    final desc = (item.description ?? '').trim();
    if (desc.isNotEmpty) return desc;

    if (item.subtaskCount > 0) return '${item.subtaskCount} 个子任务';

    final legacy = (item.legacyNote ?? '').trim();
    if (legacy.isNotEmpty) return '旧备注：$legacy';

    return null;
  }

  String? _expandedDetailLabel() {
    final desc = (item.description ?? '').trim();
    if (desc.isNotEmpty) return '描述';

    final legacy = (item.legacyNote ?? '').trim();
    if (legacy.isNotEmpty) return '旧备注（待迁移）';

    if (item.subtaskCount > 0) return '子任务';
    return null;
  }

  String? _expandedDetailText() {
    final desc = (item.description ?? '').trim();
    if (desc.isNotEmpty) return desc;

    final legacy = (item.legacyNote ?? '').trim();
    if (legacy.isNotEmpty) return legacy;

    if (item.subtaskCount > 0) return '共 ${item.subtaskCount} 个子任务（详见任务详情）';
    return null;
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

