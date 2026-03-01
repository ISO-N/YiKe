/// 文件用途：设置页“数据管理”入口区块（导出/备份/同步）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../providers/sync_provider.dart';
import '../../../widgets/glass_card.dart';

/// 数据管理入口区块。
///
/// 规范说明：
/// - 本次阶段A只做入口聚合：点击仍进入现有全屏页面（或桌面端对话框）。
/// - 不强制 Sheet 化，避免破坏导出/备份/同步的完整流程。
class DataManagementSection extends StatelessWidget {
  /// 构造函数。
  ///
  /// 参数：
  /// - [syncState] 当前同步状态（用于展示副标题口径）。
  /// 返回值：Widget。
  /// 异常：无。
  const DataManagementSection({super.key, required this.syncState});

  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数据管理', style: AppTypography.h2(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '导出、备份与同步入口聚合在此处，流程仍保持完整。',
              style: AppTypography.bodySecondary(context),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('导出'),
              subtitle: const Text('导出为 JSON / CSV 并分享到其他应用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/export'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup_outlined),
              title: const Text('备份与恢复'),
              subtitle: const Text('导出备份、导入恢复、管理历史'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/backup'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sync),
              title: const Text('局域网同步'),
              subtitle: Text(_syncSubtitle(syncState)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/sync'),
            ),
          ],
        ),
      ),
    );
  }

  String _syncSubtitle(SyncState state) {
    switch (state) {
      case SyncState.disconnected:
        return '未配对（可配对并同步）';
      case SyncState.connecting:
        return '连接中…';
      case SyncState.connected:
        return '已配对';
      case SyncState.syncing:
        return '同步中…';
      case SyncState.synced:
        return '同步完成';
      case SyncState.error:
        return '同步失败（点击查看详情）';
    }
  }
}

