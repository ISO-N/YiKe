/// 文件用途：用例 - 创建学习内容并生成复习计划（CreateLearningItemUseCase）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/learning_item.dart';
import '../entities/review_config.dart';
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
    DateTime? learningDate,
  }) : learningDate = learningDate ?? DateTime.now();

  final String title;
  final String? note;
  final List<String> tags;
  final DateTime learningDate;
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
/// 2) 基于艾宾浩斯默认间隔生成 5 条复习任务并保存
class CreateLearningItemUseCase {
  /// 构造函数。
  const CreateLearningItemUseCase({
    required LearningItemRepository learningItemRepository,
    required ReviewTaskRepository reviewTaskRepository,
  })  : _learningItemRepository = learningItemRepository,
        _reviewTaskRepository = reviewTaskRepository;

  final LearningItemRepository _learningItemRepository;
  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行用例。
  ///
  /// 返回值：创建结果（学习内容 + 生成的复习任务）。
  /// 异常：校验/数据库写入失败时可能抛出异常。
  Future<CreateLearningItemResult> execute(CreateLearningItemParams params) async {
    final now = DateTime.now();
    final learningDate = DateTime(
      params.learningDate.year,
      params.learningDate.month,
      params.learningDate.day,
    );

    final item = LearningItemEntity(
      title: params.title.trim(),
      note: params.note?.trim().isEmpty == true ? null : params.note?.trim(),
      tags: params.tags.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      learningDate: learningDate,
      createdAt: now,
      updatedAt: now,
    );

    final saved = await _learningItemRepository.create(item);

    final tasks = List<ReviewTaskEntity>.generate(
      ReviewConfig.defaultIntervals.length,
      (index) {
        final round = index + 1;
        final scheduledDate = ReviewConfig.calculateReviewDate(learningDate, round);
        return ReviewTaskEntity(
          learningItemId: saved.id!,
          reviewRound: round,
          scheduledDate: scheduledDate,
          status: ReviewTaskStatus.pending,
          createdAt: now,
        );
      },
    );

    final savedTasks = await _reviewTaskRepository.createBatch(tasks);
    return CreateLearningItemResult(item: saved, generatedTasks: savedTasks);
  }
}
