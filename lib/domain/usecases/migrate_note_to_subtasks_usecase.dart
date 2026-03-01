/// 文件用途：用例 - 数据迁移（note → description + subtasks）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import '../../core/utils/note_migration_parser.dart';
import '../repositories/task_structure_migration_repository.dart';

/// 备注迁移用例。
///
/// 说明：
/// - 用于 v2.6 任务结构增强：将历史 note 迁移到 description + learning_subtasks
/// - 迁移成功后会将 note 置空，保证幂等
class MigrateNoteToSubtasksUseCase {
  /// 构造函数。
  const MigrateNoteToSubtasksUseCase({
    required TaskStructureMigrationRepository repository,
  }) : _repository = repository;

  final TaskStructureMigrationRepository _repository;

  /// 执行迁移。
  ///
  /// 返回值：本次成功处理的 learningItem 数量（用于诊断/埋点）。
  Future<int> execute({int batchSize = 200}) async {
    var migrated = 0;

    while (true) {
      final pending = await _repository.getPendingLegacyNoteItems(
        limit: batchSize,
      );
      if (pending.isEmpty) break;

      for (final item in pending) {
        final parsed = NoteMigrationParser.parse(item.note);

        // 保护：空内容无需迁移，但仍可置空 note（让幂等锚点生效）。
        await _repository.applyMigrationForItem(
          learningItemId: item.learningItemId,
          isMockData: item.isMockData,
          migratedDescription: parsed.description,
          migratedSubtasks: parsed.subtasks,
        );
        migrated++;
      }
    }

    return migrated;
  }
}

