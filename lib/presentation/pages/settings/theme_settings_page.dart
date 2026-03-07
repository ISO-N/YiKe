/// 文件用途：主题设置页面（自定义主题色/AMOLED/实时预览）。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/entities/theme_settings.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';

/// 主题设置页。
///
/// 交互模式（符合 spec-user-experience-improvements.md）：
/// - 仅预览，不立即持久化到 settings
/// - 点击“确认”后持久化
/// - 点击“返回/取消”直接退出并恢复旧主题（因为未写入）
class ThemeSettingsPage extends ConsumerStatefulWidget {
  /// 构造函数。
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  late ThemeSettingsEntity _original;
  late String _seedHex;
  late bool _amoled;

  bool _initialized = false;
  bool _saving = false;

  static const _palette = <({String name, String hex})>[
    (name: '蓝色（默认）', hex: '#2196F3'),
    (name: '紫色', hex: '#9C27B0'),
    (name: '绿色', hex: '#4CAF50'),
    (name: '橙色', hex: '#FF9800'),
    (name: '粉色', hex: '#E91E63'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    _original = ref.read(themeSettingsProvider);
    _seedHex = _original.seedColorHex;
    _amoled = _original.amoled;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final previewSeed =
        ColorUtils.tryParseHex(_seedHex) ?? const Color(0xFF2196F3);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewTheme = isDark
        ? AppTheme.dark(seedColor: previewSeed, amoled: _amoled)
        : AppTheme.light(seedColor: previewSeed);

    Future<void> save() async {
      setState(() => _saving = true);
      try {
        final next = _original.copyWith(
          seedColorHex: _seedHex,
          amoled: _amoled,
        );
        await ref.read(themeSettingsProvider.notifier).save(next);
        // ignore: use_build_context_synchronously 的正确写法：用 context.mounted 守卫。
        if (!context.mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        leading: IconButton(
          tooltip: '取消',
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('确认'),
          ),
        ],
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
                    Text('主题色', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '选择主题种子色后，按钮、图标与图表将自动跟随配色。',
                      style: AppTypography.bodySecondary(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final item in _palette)
                          _ColorChip(
                            name: item.name,
                            hex: item.hex,
                            selected:
                                item.hex.toUpperCase() ==
                                _seedHex.toUpperCase(),
                            onTap: () => setState(() => _seedHex = item.hex),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('AMOLED 深色模式'),
                    subtitle: const Text('深色模式下使用更深的背景以节省 OLED 电量'),
                    value: _amoled,
                    onChanged: (v) => setState(() => _amoled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('实时预览', style: AppTypography.h2(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '当前仅预览，不会立刻改变全局主题；点击“确认”后才会保存。',
                      style: AppTypography.bodySecondary(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Theme(
                      data: previewTheme,
                      child: _ThemePreview(seedHex: _seedHex),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.name,
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        ColorUtils.tryParseHex(hex) ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(name),
          ],
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.seedHex});

  final String seedHex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text('主按钮'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.palette_outlined),
              label: const Text('次按钮'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.bolt, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '卡片与列表项预览（$seedHex）',
                    style: AppTypography.body(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: 0.65,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Text('65%', style: AppTypography.bodySecondary(context)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.30)),
          ),
          child: Text(
            '空状态预览：暂无数据，点击按钮开始添加内容',
            style: AppTypography.bodySecondary(context),
          ),
        ),
      ],
    );
  }
}
