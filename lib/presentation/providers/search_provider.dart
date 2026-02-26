/// 文件用途：首页学习内容搜索状态管理（v3.1 F14.1），提供搜索关键词与搜索结果。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';

/// 学习内容搜索结果（用于 UI 展示）。
class LearningItemSearchResult {
  const LearningItemSearchResult({
    required this.id,
    required this.title,
    required this.note,
    required this.learningDate,
    required this.isMockData,
  });

  final int id;
  final String title;
  final String? note;
  final DateTime learningDate;
  final bool isMockData;
}

/// 搜索关键词 Provider（原始输入，允许为空）。
final learningSearchQueryProvider = StateProvider<String>((ref) => '');

/// 搜索结果 Provider（防抖 300ms，最多 50 条）。
final learningSearchResultsProvider =
    FutureProvider.autoDispose<List<LearningItemSearchResult>>((ref) async {
      final keyword = ref.watch(learningSearchQueryProvider).trim();
      if (keyword.isEmpty) return const <LearningItemSearchResult>[];

      // v3.1：防抖，减少数据库查询频率。
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final dao = ref.read(learningItemDaoProvider);
      final rows = await dao.searchLearningItems(keyword: keyword, limit: 50);
      return rows
          .map(
            (row) => LearningItemSearchResult(
              id: row.id,
              title: row.title,
              note: row.note,
              learningDate: row.learningDate,
              isMockData: row.isMockData,
            ),
          )
          .toList();
    });
