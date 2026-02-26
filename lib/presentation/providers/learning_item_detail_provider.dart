/// 文件用途：学习内容详情 Provider（v3.1 搜索跳转），用于加载单条学习内容信息。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_item.dart';

/// 学习内容详情 Provider（按 id 获取）。
final learningItemDetailProvider = FutureProvider.family
    .autoDispose<LearningItemEntity?, int>((ref, id) {
      final repo = ref.read(learningItemRepositoryProvider);
      return repo.getById(id);
    });
