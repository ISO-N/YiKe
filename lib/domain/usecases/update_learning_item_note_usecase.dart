/// 文件用途：用例 - 更新学习内容备注（LearningItem.note）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../repositories/learning_item_repository.dart';

/// 更新学习内容备注用例。
///
/// 说明：编辑对象为 LearningItem（不是某一轮 ReviewTask）。
class UpdateLearningItemNoteUseCase {
  /// 构造函数。
  const UpdateLearningItemNoteUseCase({
    required LearningItemRepository learningItemRepository,
  }) : _learningItemRepository = learningItemRepository;

  final LearningItemRepository _learningItemRepository;

  /// 执行更新。
  ///
  /// 参数：
  /// - [learningItemId] 学习内容 ID
  /// - [note] 备注（可空；空字符串会被归一为 null）
  /// 返回值：Future（无返回值）。
  /// 异常：学习内容不存在/已停用/写入失败时可能抛出异常。
  Future<void> execute({required int learningItemId, required String? note}) {
    return _learningItemRepository.updateNote(id: learningItemId, note: note);
  }
}

