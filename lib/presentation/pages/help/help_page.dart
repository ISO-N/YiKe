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

  // 布局诊断：用于定位 Windows 端滚动条拖动“跳跃”的根因。
  // 说明：仅在 Debug 模式下打印，Release 不会产生任何开销或日志。
  final GlobalKey _headerKey = GlobalKey(debugLabel: 'help_header_card');
  final GlobalKey _tocKey = GlobalKey(debugLabel: 'help_toc_card');
  final GlobalKey _markdownKey = GlobalKey(debugLabel: 'help_markdown_card');
  final GlobalKey _footerKey = GlobalKey(debugLabel: 'help_footer_card');
  bool _hasLoggedInitialLayout = false;
  double? _lastMaxScrollExtent;

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

            // 仅 Debug：记录初次布局后的 ScrollExtent 与各区块高度，判断是否存在“页面底部还有一大块空白”
            // 导致滚动条比例异常，从而出现拖动跳跃。
            _debugLogInitialLayoutOnce();

            // 关键逻辑（Windows 白屏/跳跃修复）：
            // 诊断日志显示：拖动滚动条滑块时 maxScrollExtent 会剧烈变化（在拖动中变大/变小）。
            // 这会导致“滑块映射比例”动态变化，从而出现用户感知的“滚动条跳跃”。
            //
            // 根因通常来自 SliverList 的惰性布局：在拖动到未布局区域时，框架会逐步测量子节点高度并修正
            // scrollExtent。对于正文是超大块内容（MarkdownBody）且在桌面端拖动更频繁的场景，这种修正会更明显。
            //
            // 解决：用 SingleChildScrollView + Column 一次性布局出完整高度，让 scrollExtent 在首帧稳定。
            final scrollView = SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(
                    key: _headerKey,
                    child: _HeaderCard(tocCount: data.tocItems.length),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KeyedSubtree(
                    key: _tocKey,
                    child: _TocCard(
                      items: data.tocItems,
                      onTap: (anchorId) => _scrollToAnchor(data, anchorId),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KeyedSubtree(
                    key: _markdownKey,
                    child: GlassCard(
                      blurSigma: disableHeavyBlurOnWindows ? 0 : 14,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        // Windows 端稳定性兜底：部分环境下 Flutter 引擎的无障碍桥接会频繁报
                        // “Failed to update ui::AXTree ...”，属于引擎侧语义树同步问题。
                        // 这里对帮助页正文（Markdown）禁用语义输出，避免噪声与潜在的不稳定。
                        //
                        // 说明：这会影响屏幕阅读器读取帮助页正文，但不影响鼠标/键盘交互与文本选择复制。
                        child:
                            defaultTargetPlatform == TargetPlatform.windows
                                ? ExcludeSemantics(
                                  child: _buildMarkdownBody(
                                    context: context,
                                    data: data,
                                    builders: builders,
                                  ),
                                )
                                : _buildMarkdownBody(
                                  context: context,
                                  data: data,
                                  builders: builders,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KeyedSubtree(key: _footerKey, child: _FooterCard()),
                  const SizedBox(height: 24),
                ],
              ),
            );

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  child: scrollView,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Debug-only：打印帮助页初次布局的关键信息。
  void _debugLogInitialLayoutOnce() {
    assert(() {
      if (_hasLoggedInitialLayout) return true;
      if (defaultTargetPlatform != TargetPlatform.windows) return true;
      _hasLoggedInitialLayout = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final headerSize = _headerKey.currentContext?.size;
        final tocSize = _tocKey.currentContext?.size;
        final markdownSize = _markdownKey.currentContext?.size;
        final footerSize = _footerKey.currentContext?.size;

        debugPrint(
          'HelpPage(Windows) layout: '
          'header=$headerSize, toc=$tocSize, markdown=$markdownSize, footer=$footerSize',
        );

        if (_scrollController.hasClients) {
          final pos = _scrollController.position;
          debugPrint(
            'HelpPage(Windows) scroll: '
            'pixels=${pos.pixels.toStringAsFixed(1)}, '
            'max=${pos.maxScrollExtent.toStringAsFixed(1)}, '
            'viewport=${pos.viewportDimension.toStringAsFixed(1)}',
          );
        }
      });
      return true;
    }());
  }

  /// Debug-only：监控拖动时 ScrollMetrics 是否动态变化。
  bool _onScrollNotification(ScrollNotification notification) {
    assert(() {
      if (defaultTargetPlatform != TargetPlatform.windows) return true;

      final metrics = notification.metrics;
      final currentMax = metrics.maxScrollExtent;
      final lastMax = _lastMaxScrollExtent;
      _lastMaxScrollExtent = currentMax;

      // 只有在用户拖动导致的滚动更新时才重点关注。
      if (notification is ScrollUpdateNotification &&
          notification.dragDetails != null) {
        final delta = notification.scrollDelta ?? 0;

        // 若 maxScrollExtent 在拖动过程中发生变化，滚动条比例会变化，用户会感知为“滑块跳跃”。
        if (lastMax != null && (currentMax - lastMax).abs() > 1) {
          debugPrint(
            'HelpPage(Windows) metrics changed during drag: '
            'max $lastMax -> $currentMax, '
            'pixels=${metrics.pixels.toStringAsFixed(1)}, '
            'delta=${delta.toStringAsFixed(1)}',
          );
        }

        // 若单次滚动增量异常偏大，也打印出来辅助判断是否存在“隐藏超长内容”。
        if (delta.abs() > metrics.viewportDimension * 0.8) {
          debugPrint(
            'HelpPage(Windows) large drag update: '
            'delta=${delta.toStringAsFixed(1)}, '
            'pixels=${metrics.pixels.toStringAsFixed(1)}, '
            'max=${metrics.maxScrollExtent.toStringAsFixed(1)}, '
            'viewport=${metrics.viewportDimension.toStringAsFixed(1)}',
          );
        }
      }
      return true;
    }());

    return false;
  }

  /// 构建 Markdown 正文区域。
  ///
  /// 参数：
  /// - [context] 构建上下文
  /// - [data] 帮助页 Markdown 数据
  /// - [builders] Markdown 元素构建器（用于标题锚点）
  /// 返回值：MarkdownBody Widget。
  Widget _buildMarkdownBody({
    required BuildContext context,
    required _HelpMarkdownData data,
    required Map<String, MarkdownElementBuilder> builders,
  }) {
    return MarkdownBody(
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
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            blockquotePadding: const EdgeInsets.all(12),
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
