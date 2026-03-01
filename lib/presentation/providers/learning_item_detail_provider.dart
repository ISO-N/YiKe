/// 文件用途：学习内容详情 Provider（v3.1 搜索跳转），用于加载单条学习内容信息。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_item.dart';
import '../../domain/entities/learning_subtask.dart';

/// 学习内容详情视图对象（item + subtasks）。
class LearningItemDetailViewEntity {
  const LearningItemDetailViewEntity({
    required this.item,
    required this.subtasks,
  });

  final LearningItemEntity item;
  final List<LearningSubtaskEntity> subtasks;
}

/// 学习内容详情 Provider（按 id 获取）。
final learningItemDetailProvider = FutureProvider.family
    .autoDispose<LearningItemDetailViewEntity?, int>((ref, id) async {
      final repo = ref.read(learningItemRepositoryProvider);
      final subtaskRepo = ref.read(learningSubtaskRepositoryProvider);

      final item = await repo.getById(id);
      if (item == null) return null;
      final subtasks = await subtaskRepo.getByLearningItemId(id);
      subtasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return LearningItemDetailViewEntity(item: item, subtasks: subtasks);
    });
