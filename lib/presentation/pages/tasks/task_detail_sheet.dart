/// 文件用途：任务详情底部 Sheet（按 learningItemId 展示学习内容信息与完整复习计划）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/ebbinghaus_utils.dart';
import '../../../domain/entities/review_task.dart';
import '../../providers/task_detail_provider.dart';

/// 任务详情 Sheet。
class TaskDetailSheet extends ConsumerWidget {
  const TaskDetailSheet({super.key, required this.learningItemId});

  final int learningItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskDetailProvider(learningItemId));
    final notifier = ref.read(taskDetailProvider(learningItemId).notifier);

    void showSnack(String text) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }

    Future<void> runAction(Future<void> Function() action, {required String ok}) async {
      try {
        await action();
        showSnack(ok);
      } catch (e) {
        showSnack('操作失败：$e');
      }
    }

    final item = state.item;
    final plan = [...state.plan]..sort((a, b) => a.reviewRound.compareTo(b.reviewRound));
    final isReadOnly = item?.isDeleted ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _SheetHeader(
              title: item == null ? '任务详情' : item.title,
              isDeleted: isReadOnly,
              deletedAt: item?.deletedAt,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : item == null
                      ? _EmptyDetail(
                          message: '学习内容不存在或已被移除',
                          onBack: () => Navigator.of(context).maybePop(),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            if (state.errorMessage != null) ...[
                              _ErrorCard(message: state.errorMessage!),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            _InfoCard(
                              note: item.note,
                              tags: item.tags,
                              learningDate: item.learningDate,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ActionRow(
                              isReadOnly: isReadOnly,
                              canAddRound: _canAddRound(plan),
                              onEditNote: () async {
                                final next = await _showEditNoteDialog(
                                  context,
                                  initial: item.note,
                                  readOnly: isReadOnly,
                                );
                                if (next == null) return;
                                await runAction(
                                  () => notifier.updateNote(next),
                                  ok: '备注已更新',
                                );
                              },
                              onDeactivate: () async {
                                final confirmed = await _confirmDeactivate(context);
                                if (confirmed != true) return;
                                await runAction(
                                  notifier.deactivate,
                                  ok: '已停用学习内容',
                                );
                              },
                              onAdjustPlan: () async {
                                await _showAdjustPlanSheet(
                                  context,
                                  plan: plan,
                                  isReadOnly: isReadOnly,
                                  onAdjust: (round, date) async {
                                    await runAction(
                                      () => notifier.adjustReviewDate(
                                        reviewRound: round,
                                        newDate: date,
                                      ),
                                      ok: '计划已更新',
                                    );
                                  },
                                );
                              },
                              onAddRound: () async {
                                final confirmed = await _confirmAddRound(
                                  context,
                                  currentMaxRound: _maxRound(plan),
                                  isReadOnly: isReadOnly,
                                );
                                if (confirmed != true) return;
                                await runAction(
                                  notifier.addReviewRound,
                                  ok: '已增加一轮复习',
                                );
                              },
                              onViewPlan: () async {
                                await _showViewPlanSheet(context, plan: plan);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('复习计划', style: AppTypography.h2(context)),
                            const SizedBox(height: AppSpacing.sm),
                            if (plan.isEmpty)
                              Text(
                                '暂无复习任务',
                                style: AppTypography.bodySecondary(context),
                              )
                            else
                              ...plan.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: _PlanTile(
                                    task: t,
                                    readOnly: isReadOnly,
                                    onUndo: t.status == ReviewTaskStatus.pending || isReadOnly
                                        ? null
                                        : () async {
                                            final confirmed = await _confirmUndo(context);
                                            if (confirmed != true) return;
                                            await runAction(
                                              () => notifier.undoTaskStatus(t.taskId),
                                              ok: '已撤销',
                                            );
                                          },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAddRound(List<ReviewTaskViewEntity> plan) {
    if (plan.isEmpty) return false;
    final max = _maxRound(plan);
    return max < EbbinghausUtils.maxReviewRound;
  }

  int _maxRound(List<ReviewTaskViewEntity> plan) {
    var max = 0;
    for (final t in plan) {
      if (t.reviewRound > max) max = t.reviewRound;
    }
    return max;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.isDeleted,
    required this.deletedAt,
    required this.onClose,
  });

  final String title;
  final bool isDeleted;
  final DateTime? deletedAt;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        isDeleted ? '已停用${deletedAt == null ? '' : ' · ${DateFormat('yyyy-MM-dd HH:mm').format(deletedAt!)}'}' : null;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2(context),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodySecondary(context)),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.note,
    required this.tags,
    required this.learningDate,
  });

  final String? note;
  final List<String> tags;
  final DateTime learningDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('学习日期：${DateFormat('yyyy-MM-dd').format(learningDate)}'),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .take(12)
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text('备注', style: AppTypography.h2(context).copyWith(fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              note?.trim().isNotEmpty == true ? note!.trim() : '（无）',
              style: AppTypography.bodySecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isReadOnly,
    required this.canAddRound,
    required this.onEditNote,
    required this.onDeactivate,
    required this.onAdjustPlan,
    required this.onAddRound,
    required this.onViewPlan,
  });

  final bool isReadOnly;
  final bool canAddRound;
  final VoidCallback onEditNote;
  final VoidCallback onDeactivate;
  final VoidCallback onAdjustPlan;
  final VoidCallback onAddRound;
  final VoidCallback onViewPlan;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          onPressed: isReadOnly ? null : onEditNote,
          icon: const Icon(Icons.edit),
          label: const Text('编辑备注'),
        ),
        OutlinedButton.icon(
          onPressed: isReadOnly ? null : onAdjustPlan,
          icon: const Icon(Icons.event),
          label: const Text('调整计划'),
        ),
        OutlinedButton.icon(
          onPressed: isReadOnly || !canAddRound ? null : onAddRound,
          icon: const Icon(Icons.add),
          label: Text(canAddRound ? '增加轮次' : '已达上限'),
        ),
        OutlinedButton.icon(
          onPressed: onViewPlan,
          icon: const Icon(Icons.view_list),
          label: const Text('查看计划'),
        ),
        OutlinedButton.icon(
          onPressed: isReadOnly ? null : onDeactivate,
          icon: const Icon(Icons.pause_circle_outline),
          label: const Text('停用'),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.task, required this.readOnly, required this.onUndo});

  final ReviewTaskViewEntity task;
  final bool readOnly;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (task.status) {
      ReviewTaskStatus.pending => '待复习',
      ReviewTaskStatus.done => '已完成',
      ReviewTaskStatus.skipped => '已跳过',
    };
    final date = DateFormat('yyyy-MM-dd').format(task.scheduledDate);

    String? extra;
    if (task.status == ReviewTaskStatus.done && task.completedAt != null) {
      extra = '完成于 ${DateFormat('yyyy-MM-dd HH:mm').format(task.completedAt!)}';
    } else if (task.status == ReviewTaskStatus.skipped && task.skippedAt != null) {
      extra = '跳过于 ${DateFormat('yyyy-MM-dd HH:mm').format(task.skippedAt!)}';
    }

    return Card(
      child: ListTile(
        title: Text('第${task.reviewRound}轮 · $date'),
        subtitle: Text(extra ?? statusText),
        trailing: onUndo == null
            ? null
            : OutlinedButton(
                onPressed: onUndo,
                child: const Text('撤销'),
              ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: AppTypography.bodySecondary(context)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onBack, child: const Text('返回')),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showEditNoteDialog(
  BuildContext context, {
  required String? initial,
  required bool readOnly,
}) async {
  if (readOnly) return null;
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('编辑备注'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '请输入备注（可为空）',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _confirmDeactivate(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('停用该学习内容？'),
        content: const Text(
          '停用后该学习内容的所有复习任务将不再出现，且不会生成后续复习轮次。是否确认停用？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认停用'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _confirmUndo(BuildContext context) {
  return showDialog<bool>(
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
}

Future<bool?> _confirmAddRound(
  BuildContext context, {
  required int currentMaxRound,
  required bool isReadOnly,
}) {
  if (isReadOnly) return Future.value(false);
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('增加复习轮次'),
        content: Text(
          '当前轮次为第 $currentMaxRound 轮，将增加 1 轮复习。系统将自动计算新的复习日期，是否确认？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认增加'),
          ),
        ],
      );
    },
  );
}

Future<void> _showViewPlanSheet(
  BuildContext context, {
  required List<ReviewTaskViewEntity> plan,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final sorted = [...plan]..sort((a, b) => a.reviewRound.compareTo(b.reviewRound));
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('完整复习计划', style: AppTypography.h2(context)),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final t = sorted[index];
                    final statusText = switch (t.status) {
                      ReviewTaskStatus.pending => '待复习',
                      ReviewTaskStatus.done => '已完成',
                      ReviewTaskStatus.skipped => '已跳过',
                    };
                    return ListTile(
                      dense: true,
                      title: Text('第${t.reviewRound}轮 · ${DateFormat('yyyy-MM-dd').format(t.scheduledDate)}'),
                      subtitle: Text(statusText),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showAdjustPlanSheet(
  BuildContext context, {
  required List<ReviewTaskViewEntity> plan,
  required bool isReadOnly,
  required Future<void> Function(int reviewRound, DateTime newDate) onAdjust,
}) async {
  if (isReadOnly) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final sorted = [...plan]..sort((a, b) => a.reviewRound.compareTo(b.reviewRound));
      final tomorrow = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .add(const Duration(days: 1));

      DateTime minAllowedFor(int index) {
        final prev = index > 0 ? sorted[index - 1] : null;
        if (prev == null) return tomorrow;
        final prevDay = DateTime(prev.scheduledDate.year, prev.scheduledDate.month, prev.scheduledDate.day);
        final candidate = prevDay.add(const Duration(days: 1));
        return candidate.isAfter(tomorrow) ? candidate : tomorrow;
      }

      DateTime maxAllowedFor(int index) {
        final next = index + 1 < sorted.length ? sorted[index + 1] : null;
        if (next == null) {
          // 无硬性限制：DatePicker 需要 lastDate，这里给一个很大的上界（不作为强制产品限制）。
          return DateTime.now().add(const Duration(days: 3650));
        }
        final nextDay = DateTime(next.scheduledDate.year, next.scheduledDate.month, next.scheduledDate.day);
        return nextDay.subtract(const Duration(days: 1));
      }

      Future<void> pick(int index, {required bool isAdvance}) async {
        final t = sorted[index];
        if (t.status != ReviewTaskStatus.pending) return;

        final min = minAllowedFor(index);
        final max = maxAllowedFor(index);
        if (max.isBefore(min)) return;

        final current = DateTime(t.scheduledDate.year, t.scheduledDate.month, t.scheduledDate.day);
        final suggested = isAdvance
            ? current.subtract(const Duration(days: 1))
            : current.add(const Duration(days: 1));
        final initial = suggested.isBefore(min)
            ? min
            : (suggested.isAfter(max) ? max : suggested);

        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: min,
          lastDate: max,
          helpText: '建议不超过 1 年（仅提示，不强制）',
        );
        if (picked == null) return;
        await onAdjust(t.reviewRound, picked);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('调整后续复习计划', style: AppTypography.h2(context)),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final t = sorted[index];
                    final statusText = switch (t.status) {
                      ReviewTaskStatus.pending => '待复习',
                      ReviewTaskStatus.done => '已完成',
                      ReviewTaskStatus.skipped => '已跳过',
                    };
                    final min = minAllowedFor(index);
                    final max = maxAllowedFor(index);
                    final canAdjust =
                        t.status == ReviewTaskStatus.pending && !max.isBefore(min);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第${t.reviewRound}轮 · ${DateFormat('yyyy-MM-dd').format(t.scheduledDate)}',
                              style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(statusText, style: AppTypography.bodySecondary(context)),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: canAdjust ? () => pick(index, isAdvance: true) : null,
                                  child: const Text('提前'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                OutlinedButton(
                                  onPressed: canAdjust ? () => pick(index, isAdvance: false) : null,
                                  child: const Text('延后'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '可选范围：${DateFormat('yyyy-MM-dd').format(min)} ~ ${DateFormat('yyyy-MM-dd').format(max)}',
                              style: AppTypography.bodySecondary(context).copyWith(fontSize: 12),
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
      );
    },
  );
}

