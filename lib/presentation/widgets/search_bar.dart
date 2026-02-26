/// 文件用途：学习内容搜索栏组件（v3.1 F14.1），用于首页快速搜索学习内容。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'glass_card.dart';

/// 学习内容搜索栏。
class LearningSearchBar extends StatefulWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [query] 当前搜索关键词
  /// - [onChanged] 输入变化回调
  /// - [onClear] 清空回调
  const LearningSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
    this.enabled = true,
    this.hintText = '搜索学习内容...',
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool enabled;
  final String hintText;

  @override
  State<LearningSearchBar> createState() => _LearningSearchBarState();
}

class _LearningSearchBarState extends State<LearningSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant LearningSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: secondaryText),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTypography.bodySecondary(context),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onChanged: widget.onChanged,
              ),
            ),
            if (widget.query.trim().isNotEmpty)
              IconButton(
                tooltip: '清空',
                onPressed: widget.enabled
                    ? () {
                        widget.onClear();
                        // 交互优化：清空后保持键盘打开，由用户继续输入。
                        FocusScope.of(context).requestFocus(_focusNode);
                      }
                    : null,
                icon: const Icon(Icons.close, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

/// 高亮关键词（用于搜索结果）。
TextSpan buildHighlightedTextSpan({
  required String text,
  required String keyword,
  required TextStyle normalStyle,
  required TextStyle highlightStyle,
}) {
  final q = keyword.trim();
  if (q.isEmpty || text.isEmpty) {
    return TextSpan(text: text, style: normalStyle);
  }

  final lowerText = text.toLowerCase();
  final lowerQ = q.toLowerCase();

  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final index = lowerText.indexOf(lowerQ, start);
    if (index < 0) {
      spans.add(TextSpan(text: text.substring(start), style: normalStyle));
      break;
    }
    if (index > start) {
      spans.add(TextSpan(text: text.substring(start, index), style: normalStyle));
    }
    spans.add(
      TextSpan(
        text: text.substring(index, index + q.length),
        style: highlightStyle,
      ),
    );
    start = index + q.length;
    if (start >= text.length) break;
  }

  return TextSpan(children: spans);
}
