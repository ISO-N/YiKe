/// 文件用途：复习任务筛选栏组件（v3.1 F14.2），用于按状态筛选当日任务列表。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../providers/task_filter_provider.dart';
import 'glass_card.dart';

/// 复习任务筛选栏。
class TaskFilterBar extends StatelessWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [filter] 当前筛选
  /// - [counts] 各状态数量
  /// - [onChanged] 切换筛选回调
  const TaskFilterBar({
    super.key,
    required this.filter,
    required this.counts,
    required this.onChanged,
  });

  final ReviewTaskFilter filter;
  final TaskStatusCounts counts;
  final ValueChanged<ReviewTaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('筛选', style: AppTypography.h2(context).copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    label: '全部 ${counts.all}',
                    icon: Icons.list,
                    selected: filter == ReviewTaskFilter.all,
                    selectedColor: primary,
                    onTap: () => onChanged(ReviewTaskFilter.all),
                  ),
                  const SizedBox(width: 10),
                  _Chip(
                    label: '待复习 ${counts.pending}',
                    icon: Icons.schedule,
                    selected: filter == ReviewTaskFilter.pending,
                    selectedColor: primary,
                    onTap: () => onChanged(ReviewTaskFilter.pending),
                  ),
                  const SizedBox(width: 10),
                  _Chip(
                    label: '已完成 ${counts.done}',
                    icon: Icons.check_circle,
                    selected: filter == ReviewTaskFilter.done,
                    selectedColor: AppColors.success,
                    onTap: () => onChanged(ReviewTaskFilter.done),
                  ),
                  const SizedBox(width: 10),
                  _Chip(
                    label: '已跳过 ${counts.skipped}',
                    icon: Icons.skip_next,
                    selected: filter == ReviewTaskFilter.skipped,
                    selectedColor: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    onTap: () => onChanged(ReviewTaskFilter.skipped),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? selectedColor.withAlpha(28) : Colors.transparent;
    final border = selected ? selectedColor.withAlpha(110) : Theme.of(context).dividerColor;
    final textColor = selected ? selectedColor : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.body(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

