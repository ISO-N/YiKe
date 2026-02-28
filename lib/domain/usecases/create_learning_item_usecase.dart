/// 文件用途：用例 - 创建学习内容并生成复习计划（CreateLearningItemUseCase）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/learning_item.dart';
import '../entities/review_config.dart';
import '../entities/review_interval_config.dart';
import '../entities/review_task.dart';
import '../repositories/learning_item_repository.dart';
import '../repositories/review_task_repository.dart';

/// 创建学习内容参数。
class CreateLearningItemParams {
  /// 构造函数。
  CreateLearningItemParams({
    required this.title,
    this.note,
    this.tags = const [],
    this.reviewIntervals,
    DateTime? learningDate,
  }) : learningDate = learningDate ?? DateTime.now();

  final String title;
  final String? note;
  final List<String> tags;
  final DateTime learningDate;

  /// 复习间隔配置（可选）。
  ///
  /// 说明：
  /// - 若为空则使用默认艾宾浩斯间隔 [1,2,4,7,15]
  /// - 仅影响本次创建（不回算历史）
  final List<ReviewIntervalConfigEntity>? reviewIntervals;
}

/// 创建学习内容结果。
class CreateLearningItemResult {
  const CreateLearningItemResult({
    required this.item,
    required this.generatedTasks,
  });

  final LearningItemEntity item;
  final List<ReviewTaskEntity> generatedTasks;
}

/// 创建学习内容用例。
///
/// 逻辑：
/// 1) 保存学习内容
/// 2) 基于复习间隔配置生成 1-10 条复习任务并保存（允许禁用轮次）
class CreateLearningItemUseCase {
  /// 构造函数。
  const CreateLearningItemUseCase({
    required LearningItemRepository learningItemRepository,
    required ReviewTaskRepository reviewTaskRepository,
  }) : _learningItemRepository = learningItemRepository,
       _reviewTaskRepository = reviewTaskRepository;

  final LearningItemRepository _learningItemRepository;
  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行用例。
  ///
  /// 返回值：创建结果（学习内容 + 生成的复习任务）。
  /// 异常：校验/数据库写入失败时可能抛出异常。
  Future<CreateLearningItemResult> execute(
    CreateLearningItemParams params,
  ) async {
    final now = DateTime.now();
    final learningDate = DateTime(
      params.learningDate.year,
      params.learningDate.month,
      params.learningDate.day,
    );

    final item = LearningItemEntity(
      title: params.title.trim(),
      note: params.note?.trim().isEmpty == true ? null : params.note?.trim(),
      tags: params.tags
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      learningDate: learningDate,
      createdAt: now,
      updatedAt: now,
    );

    final saved = await _learningItemRepository.create(item);

    final configs = _normalizeIntervals(params.reviewIntervals);

    final tasks =
        configs
            .where((e) => e.enabled)
            .map(
              (c) => ReviewTaskEntity(
                learningItemId: saved.id!,
                reviewRound: c.round,
                scheduledDate: learningDate.add(Duration(days: c.intervalDays)),
                status: ReviewTaskStatus.pending,
                createdAt: now,
              ),
            )
            .toList()
          ..sort((a, b) => a.reviewRound.compareTo(b.reviewRound));

    final savedTasks = await _reviewTaskRepository.createBatch(tasks);
    return CreateLearningItemResult(item: saved, generatedTasks: savedTasks);
  }

  List<ReviewIntervalConfigEntity> _normalizeIntervals(
    List<ReviewIntervalConfigEntity>? raw,
  ) {
    if (raw == null || raw.isEmpty) {
      return List<ReviewIntervalConfigEntity>.generate(
        ReviewConfig.defaultIntervals.length,
        (index) => ReviewIntervalConfigEntity(
          round: index + 1,
          intervalDays: ReviewConfig.defaultIntervals[index],
          enabled: true,
        ),
      );
    }

    // 关键逻辑：保证 round 唯一且范围合法，避免生成重复/越界任务。
    final map = <int, ReviewIntervalConfigEntity>{};
    for (final c in raw) {
      if (c.round < 1 || c.round > 10) continue;
      if (c.intervalDays < 1) continue;
      map[c.round] = c;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.round.compareTo(b.round));
    final hasEnabled = list.any((e) => e.enabled);
    if (!hasEnabled) {
      throw ArgumentError('至少保留一轮复习');
    }
    return list;
  }
}
