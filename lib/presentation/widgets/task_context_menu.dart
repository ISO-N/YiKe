/// 文件用途：任务卡片上下文菜单（长按/右键）组件封装（v1.1.0 体验增强）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:flutter/material.dart';

import '../../domain/entities/review_task.dart';

/// 任务上下文菜单动作。
enum TaskContextMenuAction {
  /// 完成任务。
  complete,

  /// 跳过任务。
  skip,

  /// 撤销任务状态（done/skipped → pending）。
  undo,

  /// 查看详情（跳转到任务详情页）。
  viewDetail,
}

/// 弹出任务上下文菜单。
///
/// 说明：
/// - 仅负责“展示菜单 + 返回选择结果”，不直接执行数据库操作
/// - 菜单项矩阵遵循 spec-enhancement-v1.1.0：
///   - pending：完成 / 跳过 / 查看详情
///   - done/skipped：撤销 / 查看详情
///
/// 参数：
/// - [context] BuildContext。
/// - [globalPosition] 手势的全局坐标（用于定位菜单）。
/// - [status] 任务状态。
/// 返回值：用户选择的动作；点空白处/取消返回 null。
Future<TaskContextMenuAction?> showTaskContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required ReviewTaskStatus status,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(globalPosition, globalPosition),
    Offset.zero & overlay.size,
  );

  final items = <PopupMenuEntry<TaskContextMenuAction>>[
    if (status == ReviewTaskStatus.pending) ...[
      const PopupMenuItem(
        value: TaskContextMenuAction.complete,
        child: _MenuRow(icon: Icons.check_circle_outline, text: '完成'),
      ),
      const PopupMenuItem(
        value: TaskContextMenuAction.skip,
        child: _MenuRow(icon: Icons.not_interested_outlined, text: '跳过'),
      ),
      const PopupMenuItem(
        value: TaskContextMenuAction.viewDetail,
        child: _MenuRow(icon: Icons.visibility_outlined, text: '查看详情'),
      ),
    ] else ...[
      const PopupMenuItem(
        value: TaskContextMenuAction.undo,
        child: _MenuRow(icon: Icons.undo, text: '撤销'),
      ),
      const PopupMenuItem(
        value: TaskContextMenuAction.viewDetail,
        child: _MenuRow(icon: Icons.visibility_outlined, text: '查看详情'),
      ),
    ],
  ];

  return showMenu<TaskContextMenuAction>(
    context: context,
    position: position,
    items: items,
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(text)],
    );
  }
}
