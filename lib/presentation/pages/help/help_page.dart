/// 文件用途：帮助页（F10）——内嵌展示《忆刻学习指南》，支持 Markdown 渲染与目录跳转。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/glass_card.dart';

/// 学习指南资源路径（运行时从 assets 读取）。
const String _kLearningGuideAssetPath = 'assets/markdown/learning_guide.md';

/// 帮助页：展示学习指南内容。
class HelpPage extends StatefulWidget {
  /// 构造函数。
  ///
  /// 返回值：帮助页 Widget。
  /// 异常：无。
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final ScrollController _scrollController = ScrollController();
  Future<_HelpMarkdownData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAndParse();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<_HelpMarkdownData> _loadAndParse() async {
    final raw = await rootBundle.loadString(_kLearningGuideAssetPath);
    final tocItems = _parseToc(raw);

    // 目录锚点：为每个标题生成一个 GlobalKey，便于点击目录后滚动定位。
    final anchorKeys = <String, GlobalKey>{};
    for (final item in tocItems) {
      anchorKeys[item.anchorId] = GlobalKey(debugLabel: item.anchorId);
    }

    return _HelpMarkdownData(
      markdown: raw,
      tocItems: tocItems,
      anchorKeys: anchorKeys,
    );
  }

  List<_TocItem> _parseToc(String markdown) {
    final items = <_TocItem>[];
    final lines = markdown.split('\n');
    var counter = 0;

    for (final line in lines) {
      final trimmed = line.trimRight();
      if (!trimmed.startsWith('#')) continue;

      // 仅收集二级/三级标题，避免目录过于冗长。
      final match = RegExp(r'^(#{2,3})\s+(.+)$').firstMatch(trimmed);
      if (match == null) continue;

      final levelMarks = match.group(1)!;
      final title = match.group(2)!.trim();
      if (title.isEmpty) continue;

      final level = levelMarks.length;
      final anchorId = 'h${level}_${counter++}';
      items.add(_TocItem(title: title, level: level, anchorId: anchorId));
    }

    return items;
  }

  Future<void> _scrollToAnchor(_HelpMarkdownData data, String anchorId) async {
    final key = data.anchorKeys[anchorId];
    final targetContext = key?.currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.12,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Windows 端体验优化：大面积 BackdropFilter 在滚动/拖动滚动条时容易产生明显卡顿，
    // 用户会感知为“滚动条拖动时突然跳很多”。这里对帮助页正文的大块区域禁用模糊，保留半透明样式。
    final disableHeavyBlurOnWindows =
        defaultTargetPlatform == TargetPlatform.windows;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.learningGuideTitle)),
      body: SafeArea(
        child: FutureBuilder<_HelpMarkdownData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      '学习指南加载失败：${snapshot.error}',
                      style: AppTypography.bodySecondary(context),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final builders = <String, MarkdownElementBuilder>{};
            final headerAnchors = _HeaderAnchorBuilder(data: data);
            builders['h2'] = headerAnchors;
            builders['h3'] = headerAnchors;

            // 关键逻辑（Windows 体验修复）：
            // Flutter 在桌面端会通过默认 ScrollBehavior 自动包一层 Scrollbar。
            // 在部分 Windows 环境下，自动 Scrollbar 的拖动会出现“滑块跳跃”的交互问题。
            // 这里显式提供 Scrollbar + controller，并关闭该子树的自动 Scrollbar，确保拖动行为稳定。
            final listView = ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _HeaderCard(tocCount: data.tocItems.length),
                const SizedBox(height: AppSpacing.lg),
                _TocCard(
                  items: data.tocItems,
                  onTap: (anchorId) => _scrollToAnchor(data, anchorId),
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassCard(
                  blurSigma: disableHeavyBlurOnWindows ? 0 : 14,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: MarkdownBody(
                      data: data.markdown,
                      selectable: true,
                      builders: builders,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            h1: Theme.of(context).textTheme.headlineMedium,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                            p: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.6),
                            blockquotePadding: const EdgeInsets.all(12),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _FooterCard(),
                const SizedBox(height: 24),
              ],
            );

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: listView,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HelpMarkdownData {
  _HelpMarkdownData({
    required this.markdown,
    required this.tocItems,
    required this.anchorKeys,
  });

  final String markdown;
  final List<_TocItem> tocItems;
  final Map<String, GlobalKey> anchorKeys;
}

class _TocItem {
  _TocItem({required this.title, required this.level, required this.anchorId});

  final String title;
  final int level; // 2 或 3
  final String anchorId;
}

/// 目录卡片：点击目录跳转到指定章节。
class _TocCard extends StatelessWidget {
  const _TocCard({required this.items, required this.onTap});

  final List<_TocItem> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('目录为空', style: AppTypography.bodySecondary(context)),
        ),
      );
    }

    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          title: Text('目录', style: AppTypography.h2(context)),
          subtitle: Text(
            '点击跳转到对应章节',
            style: AppTypography.bodySecondary(context),
          ),
          children: [
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.only(
                  left: item.level == 3 ? AppSpacing.lg : 0,
                  right: 0,
                ),
                leading: Icon(
                  item.level == 3 ? Icons.subdirectory_arrow_right : Icons.menu,
                  size: 18,
                ),
                title: Text(item.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTap(item.anchorId),
              ),
          ],
        ),
      ),
    );
  }
}

/// 顶部 Header：标题与副标题。
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.tocCount});

  final int tocCount;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.school_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.learningGuideTitle,
                    style: AppTypography.h2(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '科学学习方法，让记忆更牢固',
                    style: AppTypography.bodySecondary(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('$tocCount 节', style: AppTypography.bodySecondary(context)),
          ],
        ),
      ),
    );
  }
}

/// 底部 Footer：版本信息提示。
class _FooterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本信息', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '学习指南来源：docs/prd/忆刻学习指南.md（单一事实源）',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '资源文件：assets/markdown/learning_guide.md（自动生成）',
              style: AppTypography.bodySecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Markdown 标题锚点构建器：为 H2/H3 插入 GlobalKey，支持目录跳转。
class _HeaderAnchorBuilder extends MarkdownElementBuilder {
  _HeaderAnchorBuilder({required this.data});

  final _HelpMarkdownData data;
  int _index = 0;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // 关键逻辑：Markdown 渲染时标题的构建顺序与解析目录一致，按序绑定锚点。
    final anchorId = _index < data.tocItems.length
        ? data.tocItems[_index++].anchorId
        : null;
    final key = anchorId == null ? null : data.anchorKeys[anchorId];

    final text = element.textContent.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      key: key,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(text, style: preferredStyle),
    );
  }
}
