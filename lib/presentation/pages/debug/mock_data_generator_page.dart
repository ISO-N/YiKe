/// 文件用途：Debug 模拟数据生成器页面（v3.1），用于一键生成/清理模拟数据。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../infrastructure/debug/mock_data_service.dart';
import '../../providers/mock_data_provider.dart';
import '../../widgets/glass_card.dart';

/// Debug 模拟数据生成器页面。
class MockDataGeneratorPage extends ConsumerStatefulWidget {
  /// 构造函数。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const MockDataGeneratorPage({super.key});

  @override
  ConsumerState<MockDataGeneratorPage> createState() =>
      _MockDataGeneratorPageState();
}

class _MockDataGeneratorPageState extends ConsumerState<MockDataGeneratorPage> {
  late final TextEditingController _contentCountController;
  late final TextEditingController _taskCountController;
  late final TextEditingController _customPrefixController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(mockDataProvider);
    _contentCountController = TextEditingController(
      text: state.contentCount.toString(),
    );
    _taskCountController = TextEditingController(text: state.taskCount.toString());
    _customPrefixController = TextEditingController(text: state.customPrefix);
  }

  @override
  void dispose() {
    _contentCountController.dispose();
    _taskCountController.dispose();
    _customPrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('模拟数据生成器')),
        body: const Center(child: Text('仅 Debug 模式可用')),
      );
    }

    final state = ref.watch(mockDataProvider);
    final notifier = ref.read(mockDataProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    final isRunning = state.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('模拟数据生成器'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('配置', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '仅在 Debug 模式下可用；生成的数据会标记为 Mock，并自动排除同步/导出。',
                      style: AppTypography.bodySecondary(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _NumberField(
                      label: '学习内容数量（1-100）',
                      controller: _contentCountController,
                      enabled: !isRunning,
                      onChanged: (v) => notifier.setContentCount(v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _NumberField(
                      label: '复习任务数量（1-500）',
                      controller: _taskCountController,
                      enabled: !isRunning,
                      onChanged: (v) => notifier.setTaskCount(v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DaysRangeField(
                      value: state.daysRange,
                      enabled: !isRunning,
                      onChanged: (v) => notifier.setDaysRange(v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TemplateField(
                      value: state.template,
                      enabled: !isRunning,
                      onChanged: (v) => notifier.setTemplate(v),
                    ),
                    if (state.template == MockDataTemplate.custom) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _customPrefixController,
                        enabled: !isRunning,
                        decoration: const InputDecoration(
                          labelText: '自定义模板前缀',
                          hintText: '例如：高数/背诵/面试',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: notifier.setCustomPrefix,
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
                    Text('操作', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: isRunning ? null : () => notifier.generate(),
                        style: FilledButton.styleFrom(backgroundColor: primary),
                        child: isRunning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('生成数据'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed:
                            isRunning ? null : () async => _confirmClearMock(
                              context: context,
                              onConfirmed: () => notifier.clearMockData(),
                            ),
                        child: const Text('清理模拟数据（按 Mock 标记）'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: isRunning
                            ? null
                            : () async => _confirmClearAll(
                              context: context,
                              onConfirmed: () => notifier.clearAllData(),
                            ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('清空全部业务数据（危险）'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.message != null) ...[
                      Text(
                        state.message!,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (state.errorMessage != null) ...[
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearMock({
    required BuildContext context,
    required Future<void> Function() onConfirmed,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认清理模拟数据？'),
          content: const Text('将删除所有标记为 Mock 的学习内容与复习任务。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await onConfirmed();
  }

  Future<void> _confirmClearAll({
    required BuildContext context,
    required Future<void> Function() onConfirmed,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认清空全部业务数据？'),
          content: const Text('该操作不可撤销，仅建议在开发调试环境使用。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('继续清空'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await onConfirmed();
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (raw) {
        final v = int.tryParse(raw);
        if (v == null) return;
        onChanged(v);
      },
    );
  }
}

class _DaysRangeField extends StatelessWidget {
  const _DaysRangeField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: '复习日期范围（最近 N 天）',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 7, child: Text('最近 7 天')),
        DropdownMenuItem(value: 14, child: Text('最近 14 天')),
        DropdownMenuItem(value: 30, child: Text('最近 30 天')),
        DropdownMenuItem(value: 60, child: Text('最近 60 天')),
        DropdownMenuItem(value: 90, child: Text('最近 90 天')),
      ],
      onChanged: enabled ? (v) => v == null ? null : onChanged(v) : null,
    );
  }
}

class _TemplateField extends StatelessWidget {
  const _TemplateField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final MockDataTemplate value;
  final bool enabled;
  final ValueChanged<MockDataTemplate> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MockDataTemplate>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: '生成模板',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: MockDataTemplate.random,
          child: Text('随机'),
        ),
        DropdownMenuItem(
          value: MockDataTemplate.englishWords,
          child: Text('英语单词'),
        ),
        DropdownMenuItem(
          value: MockDataTemplate.historyEvents,
          child: Text('历史事件'),
        ),
        DropdownMenuItem(
          value: MockDataTemplate.custom,
          child: Text('自定义'),
        ),
      ],
      onChanged: enabled ? (v) => v == null ? null : onChanged(v) : null,
    );
  }
}
