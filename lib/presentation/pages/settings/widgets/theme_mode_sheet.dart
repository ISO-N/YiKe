/// 文件用途：主题模式选择底部弹窗（跟随系统/浅色/深色）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/theme_provider.dart';

/// 主题模式选择底部弹窗。
class ThemeModeSheet extends ConsumerWidget {
  /// 构造函数。
  const ThemeModeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final dividerColor = Theme.of(context).dividerColor;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // 交互提示：可拖拽关闭。
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '选择主题模式',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...AppThemeMode.values.map(
              (mode) => RadioListTile<AppThemeMode>(
                value: mode,
                groupValue: currentMode,
                title: Text(mode.label),
                subtitle: Text(_getSubtitle(mode)),
                onChanged: (value) async {
                  if (value == null) return;
                  await ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(value);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return '自动跟随手机设置';
      case AppThemeMode.light:
        return '明亮模式';
      case AppThemeMode.dark:
        return '护眼模式，适配夜间';
    }
  }
}

