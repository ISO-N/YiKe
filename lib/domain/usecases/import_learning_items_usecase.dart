/// 文件用途：用例 - 批量导入学习内容（ImportLearningItemsUseCase），用于批量导入（F1.1）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'create_learning_item_usecase.dart';

/// 批量导入结果。
class ImportResult {
  /// 构造函数。
  const ImportResult({
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  final int successCount;
  final int failedCount;
  final List<String> errors;
}

/// 批量导入用例。
///
/// 策略：
/// - 复用 [CreateLearningItemUseCase]，确保复习任务生成逻辑一致
/// - 逐条失败不中断，累计失败原因后统一返回
/// - 大批量数据分批处理，避免一次性占用过多资源
class ImportLearningItemsUseCase {
  /// 构造函数。
  const ImportLearningItemsUseCase({required CreateLearningItemUseCase create})
    : _create = create;

  final CreateLearningItemUseCase _create;

  /// 执行批量导入。
  ///
  /// 参数：
  /// - [items] 待导入条目（以创建参数表示）
  /// 返回值：导入结果统计
  Future<ImportResult> execute(List<CreateLearningItemParams> items) async {
    if (items.isEmpty) {
      return const ImportResult(successCount: 0, failedCount: 0, errors: []);
    }

    const batchSize = 100;
    var success = 0;
    var failed = 0;
    final errors = <String>[];

    for (var i = 0; i < items.length; i += batchSize) {
      final batch = items.sublist(
        i,
        (i + batchSize) > items.length ? items.length : (i + batchSize),
      );
      for (final params in batch) {
        try {
          await _create.execute(params);
          success++;
        } catch (e) {
          failed++;
          final title = params.title.trim();
          errors.add(title.isEmpty ? '导入失败：$e' : '「$title」导入失败：$e');
        }
      }
    }

    return ImportResult(
      successCount: success,
      failedCount: failed,
      errors: errors,
    );
  }
}
