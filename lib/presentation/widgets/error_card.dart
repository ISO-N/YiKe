/// 文件用途：通用错误提示卡片组件，用于展示加载失败等错误信息。
/// 作者：Codex
/// 创建日期：2026-03-04
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'glass_card.dart';

/// 错误信息卡片。
///
/// 参数：
/// - [message] 错误信息内容。
/// - [onRetry] 可选的重新加载回调。
/// 返回值：Widget。
/// 异常：无。
class ErrorCard extends StatelessWidget {
  /// 错误卡片。
  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// 错误信息。
  final String message;

  /// 重新加载回调（可选）。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '加载失败：$message',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onRetry,
                  child: const Text('重试'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
