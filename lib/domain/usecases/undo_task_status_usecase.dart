/// 文件用途：用例 - 撤销任务状态（done/skipped → pending）。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import '../repositories/review_task_repository.dart';

/// 撤销任务状态用例。
class UndoTaskStatusUseCase {
  /// 构造函数。
  const UndoTaskStatusUseCase({
    required ReviewTaskRepository reviewTaskRepository,
  }) : _reviewTaskRepository = reviewTaskRepository;

  final ReviewTaskRepository _reviewTaskRepository;

  /// 执行撤销。
  ///
  /// 参数：
  /// - [id] 任务 ID
  /// 返回值：Future（无返回值）。
  /// 异常：数据库更新失败时可能抛出异常。
  Future<void> execute(int id) {
    return _reviewTaskRepository.undoTaskStatus(id);
  }
}

