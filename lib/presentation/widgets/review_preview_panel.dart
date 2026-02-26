/// 文件用途：复习计划预览面板（ReviewPreviewPanel），支持展开/收起、间隔调整与启用开关（F1.5）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../domain/entities/review_interval_config.dart';
import '../providers/review_intervals_provider.dart';
import 'glass_card.dart';

class ReviewPreviewPanel extends ConsumerStatefulWidget {
  /// 复习计划预览面板。
  ///
  /// 参数：
  /// - [learningDate] 学习日期（用于计算预览日期，按年月日）
  const ReviewPreviewPanel({super.key, required this.learningDate});

  final DateTime learningDate;

  @override
  ConsumerState<ReviewPreviewPanel> createState() => _ReviewPreviewPanelState();
}

class _ReviewPreviewPanelState extends ConsumerState<ReviewPreviewPanel> {
  bool _expanded = false;
  List<ReviewIntervalConfigEntity> _draft = const [];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewIntervalsProvider);
    final notifier = ref.read(reviewIntervalsProvider.notifier);

    if (!state.isLoading && _draft.isEmpty && state.configs.isNotEmpty) {
      // 首次同步：避免每次 build 覆盖用户正在拖动的本地草稿。
      _draft = [...state.configs];
    }

    Widget header() {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text('复习计划预览', style: AppTypography.h2),
              ),
              Text(
                '默认复习间隔',
                style: AppTypography.bodySecondary.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoading) {
      return GlassCard(
        child: Column(
          children: [
            header(),
            if (_expanded)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      );
    }

    final enabledCount = _draft.where((e) => e.enabled).length;

    return GlassCard(
      child: Column(
        children: [
          header(),
          AnimatedCrossFade(
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已启用 $enabledCount / ${_draft.length} 轮',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._draft.map((c) => _RoundTile(
                        config: c,
                        learningDate: widget.learningDate,
                        onToggle: (v) async {
                          final next = _draft
                              .map(
                                (e) => e.round == c.round
                                    ? e.copyWith(enabled: v)
                                    : e,
                              )
                              .toList();
                          if (!next.any((e) => e.enabled)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('至少保留一轮复习')),
                            );
                            return;
                          }
                          setState(() => _draft = next);
                          await notifier.save(next);
                        },
                        onIntervalChanged: (value) {
                          setState(() {
                            _draft = _draft
                                .map(
                                  (e) => e.round == c.round
                                      ? e.copyWith(intervalDays: value)
                                      : e,
                                )
                                .toList();
                          });
                        },
                        onIntervalChangeEnd: (value) async {
                          final next = _draft
                              .map(
                                (e) => e.round == c.round
                                    ? e.copyWith(intervalDays: value)
                                    : e,
                              )
                              .toList();
                          await notifier.save(next);
                        },
                      )),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await notifier.resetDefault();
                          setState(() => _draft = [...ref.read(reviewIntervalsProvider).configs]);
                        },
                        child: const Text('恢复默认'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () async {
                          await notifier.enableAll();
                          setState(() => _draft = [...ref.read(reviewIntervalsProvider).configs]);
                        },
                        child: const Text('启用全部'),
                      ),
                      const Spacer(),
                      if (state.errorMessage != null)
                        Text(
                          '保存失败：${state.errorMessage}',
                          style: AppTypography.bodySecondary.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundTile extends StatelessWidget {
  const _RoundTile({
    required this.config,
    required this.learningDate,
    required this.onToggle,
    required this.onIntervalChanged,
    required this.onIntervalChangeEnd,
  });

  final ReviewIntervalConfigEntity config;
  final DateTime learningDate;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onIntervalChangeEnd;

  @override
  Widget build(BuildContext context) {
    final date = DateTime(learningDate.year, learningDate.month, learningDate.day)
        .add(Duration(days: config.intervalDays));
    final dateText =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '第${config.round}次复习  +${config.intervalDays}天  $dateText',
                      style: AppTypography.body,
                    ),
                  ),
                  Switch(
                    value: config.enabled,
                    onChanged: onToggle,
                  ),
                ],
              ),
              Slider(
                min: 1,
                max: 60,
                divisions: 59,
                value: config.intervalDays.toDouble(),
                label: '${config.intervalDays}',
                onChanged: config.enabled
                    ? (v) => onIntervalChanged(v.round())
                    : null,
                onChangeEnd: config.enabled
                    ? (v) => onIntervalChangeEnd(v.round())
                    : null,
              ),
              if (config.intervalDays > 30)
                Text(
                  '间隔过长可能导致遗忘',
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
