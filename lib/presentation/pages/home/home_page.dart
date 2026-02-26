/// 文件用途：首页（今日复习任务），展示今日/逾期任务并支持完成、跳过与批量操作。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/learning_topic.dart';
import '../../../domain/entities/review_task.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/home_tasks_provider.dart';
import '../../providers/notification_permission_provider.dart';
import '../../providers/settings_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  /// 首页（今日复习）。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // 防止弹窗在一次会话内重复出现。
  bool _permissionDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    final state = ref.watch(homeTasksProvider);
    final notifier = ref.read(homeTasksProvider.notifier);
    final settingsState = ref.watch(settingsProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);

    final permission = permissionAsync.valueOrNull;
    final shouldPromptPermission =
        !settingsState.isLoading &&
        settingsState.settings.notificationsEnabled &&
        !settingsState.settings.notificationPermissionGuideDismissed &&
        permission == NotificationPermissionState.disabled;

    if (shouldPromptPermission && !_permissionDialogShown) {
      _permissionDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showNotificationPermissionDialog(
          context: context,
          ref: ref,
          settings: settingsState.settings,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.todayReview),
        actions: [
          IconButton(
            tooltip: state.topicFilterId == null
                ? '筛选：全部'
                : '筛选：主题 #${state.topicFilterId}',
            onPressed: state.isLoading ? null : () => _showTopicFilterSheet(),
            icon: Icon(
              Icons.filter_list,
              color: state.topicFilterId == null
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
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
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const _DateHeader(),
                const SizedBox(height: AppSpacing.lg),
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
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else ...[
                  if (state.todayPending.length + state.overduePending.length >
                      20) ...[
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '今日任务较多，建议优先完成逾期任务。',
                                style: AppTypography.bodySecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (state.overduePending.isNotEmpty) ...[
                    _SectionHeader(
                      title: '逾期任务',
                      subtitle: '优先处理红色逾期任务，避免堆积',
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TaskGrid(
                      tasks: state.overduePending,
                      isOverdue: true,
                      selectionMode: state.isSelectionMode,
                      selectedTaskIds: state.selectedTaskIds,
                      onToggleSelected: notifier.toggleSelected,
                      onComplete: notifier.completeTask,
                      onSkip: notifier.skipTask,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _SectionHeader(
                    title: '今日待复习',
                    subtitle: state.todayPending.isEmpty ? '今天没有待复习任务' : null,
                    color: primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.todayPending.isEmpty &&
                      state.overduePending.isEmpty)
                    const _EmptyState()
                  else if (state.todayPending.isEmpty)
                    const _EmptySectionHint(text: AppStrings.emptyTodayTasks)
                  else
                    _TaskGrid(
                      tasks: state.todayPending,
                      isOverdue: false,
                      selectionMode: state.isSelectionMode,
                      selectedTaskIds: state.selectedTaskIds,
                      onToggleSelected: notifier.toggleSelected,
                      onComplete: notifier.completeTask,
                      onSkip: notifier.skipTask,
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
              onCompleteSelected: state.selectedTaskIds.isEmpty
                  ? null
                  : notifier.completeSelected,
              onSkipSelected: state.selectedTaskIds.isEmpty
                  ? null
                  : notifier.skipSelected,
            )
          : null,
    );
  }

  Future<void> _showTopicFilterSheet() async {
    final current = ref.read(homeTasksProvider).topicFilterId;
    List<LearningTopicEntity> topics = const [];
    try {
      topics = await ref.read(manageTopicUseCaseProvider).getAll();
    } catch (_) {
      // 主题加载失败时仍允许切回“全部”。
    }
    if (!mounted) return;

    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('全部'),
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(-1),
              ),
              const Divider(height: 1),
              if (topics.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '暂无主题',
                    style: AppTypography.bodySecondary(context),
                  ),
                )
              else
                ...topics.map((t) {
                  return ListTile(
                    title: Text(t.name),
                    subtitle: (t.description ?? '').trim().isEmpty
                        ? null
                        : Text(
                            t.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: current == t.id ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(context).pop(t.id!),
                  );
                }),
            ],
          ),
        );
      },
    );

    if (picked == null) return;
    final next = picked == -1 ? null : picked;
    await ref.read(homeTasksProvider.notifier).setTopicFilter(next);
  }
}

Future<void> _showNotificationPermissionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AppSettingsEntity settings,
}) async {
  final settingsNotifier = ref.read(settingsProvider.notifier);

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('开启通知，确保及时复习'),
        content: const Text(
          '检测到系统通知权限未开启。\n\n'
          '为了在每日提醒时间收到复习通知（v1.0 允许 ±30 分钟误差），请前往系统设置开启通知权限。',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await settingsNotifier.save(
                settings.copyWith(notificationPermissionGuideDismissed: true),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('不再提示'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () async {
              await AppSettings.openAppSettings(
                type: AppSettingsType.notification,
              );
              ref.invalidate(notificationPermissionProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('去开启'),
          ),
        ],
      );
    },
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressTrackColor = isDark ? AppColors.darkDivider : Colors.white;

    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日进度', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: progressTrackColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
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

class _DateHeader extends StatelessWidget {
  const _DateHeader();

  @override
  Widget build(BuildContext context) {
    final secondaryText =
        Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary;

    final now = DateTime.now();
    final weekday = _weekdayZh(now.weekday);
    final text = '${YikeDateUtils.formatYmd(now)}  $weekday';
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 18, color: secondaryText),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.body(
            context,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _weekdayZh(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '周一';
      case DateTime.tuesday:
        return '周二';
      case DateTime.wednesday:
        return '周三';
      case DateTime.thursday:
        return '周四';
      case DateTime.friday:
        return '周五';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
      default:
        return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    required this.color,
  });

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
        Text(title, style: AppTypography.h2(context)),
        if (subtitle != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              subtitle!,
              style: AppTypography.bodySecondary(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskGrid extends StatelessWidget {
  const _TaskGrid({
    required this.tasks,
    required this.isOverdue,
    required this.selectionMode,
    required this.selectedTaskIds,
    required this.onToggleSelected,
    required this.onComplete,
    required this.onSkip,
  });

  final List<ReviewTaskViewEntity> tasks;
  final bool isOverdue;
  final bool selectionMode;
  final Set<int> selectedTaskIds;
  final void Function(int taskId) onToggleSelected;
  final void Function(int taskId) onComplete;
  final void Function(int taskId) onSkip;

  @override
  Widget build(BuildContext context) {
    final columnCount = ResponsiveUtils.getColumnCount(context);

    // 移动端/窄屏：保持单列 + 滑动操作。
    if (columnCount <= 1) {
      return Column(
        children: tasks
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _TaskCard(
                  taskId: t.taskId,
                  title: t.title,
                  tags: t.tags,
                  reviewRound: t.reviewRound,
                  scheduledDate: t.scheduledDate,
                  isOverdue: isOverdue,
                  selectionMode: selectionMode,
                  selected: selectedTaskIds.contains(t.taskId),
                  onToggleSelected: () => onToggleSelected(t.taskId),
                  onComplete: () => onComplete(t.taskId),
                  onSkip: () => onSkip(t.taskId),
                ),
              ),
            )
            .toList(),
      );
    }

    // 桌面/宽屏：多列网格，关闭滑动（桌面端用按钮/快捷键更符合预期）。
    final itemExtent = selectionMode ? 168.0 : 156.0;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: itemExtent,
      ),
      itemBuilder: (context, index) {
        final t = tasks[index];
        return _TaskCard(
          taskId: t.taskId,
          title: t.title,
          tags: t.tags,
          reviewRound: t.reviewRound,
          scheduledDate: t.scheduledDate,
          isOverdue: isOverdue,
          selectionMode: selectionMode,
          selected: selectedTaskIds.contains(t.taskId),
          enableSwipe: false,
          onToggleSelected: () => onToggleSelected(t.taskId),
          onComplete: () => onComplete(t.taskId),
          onSkip: () => onSkip(t.taskId),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.taskId,
    required this.title,
    required this.tags,
    required this.reviewRound,
    required this.scheduledDate,
    required this.isOverdue,
    required this.selectionMode,
    required this.selected,
    this.enableSwipe = true,
    required this.onToggleSelected,
    required this.onComplete,
    required this.onSkip,
  });

  final int taskId;
  final String title;
  final List<String> tags;
  final int reviewRound;
  final DateTime scheduledDate;
  final bool isOverdue;
  final bool selectionMode;
  final bool selected;
  final bool enableSwipe;
  final VoidCallback onToggleSelected;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalBorderColor = isDark
        ? AppColors.darkGlassBorder
        : AppColors.glassBorder;
    final secondaryText =
        Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    final borderColor = isOverdue ? AppColors.warning : normalBorderColor;
    final dueText = _dueText();

    final card = GlassCard(
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
                  color: isOverdue ? AppColors.warning : secondaryText,
                  size: 22,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title（第$reviewRound次）',
                      style: AppTypography.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(dueText, style: AppTypography.bodySecondary(context)),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .take(3)
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.35),
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
                      color: secondaryText,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    if (selectionMode || !enableSwipe) return card;

    return Dismissible(
      key: ValueKey('task_$taskId'),
      direction: DismissDirection.horizontal,
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.success,
        icon: Icons.check,
        text: '完成',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Icons.not_interested,
        text: '跳过',
      ),
      confirmDismiss: (direction) async {
        // 避免误触：仅在滑动距离足够时触发（Dismissible 自带阈值），这里直接允许。
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else if (direction == DismissDirection.endToStart) {
          onSkip();
        }
      },
      child: card,
    );
  }

  String _dueText() {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final scheduledStart = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final diffDays = todayStart.difference(scheduledStart).inDays;
    if (diffDays <= 0) return '今日待复习';
    return '逾期 $diffDays 天';
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.text,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已选择 $selectedCount 项',
                    style: AppTypography.bodySecondary(context),
                  ),
                ),
                FilledButton(
                  onPressed: onCompleteSelected,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
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
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.emptyTodayTasks,
              style: AppTypography.bodySecondary(context),
              textAlign: TextAlign.center,
            ),
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
        style: AppTypography.bodySecondary(context),
        textAlign: TextAlign.center,
      ),
    );
  }
}
