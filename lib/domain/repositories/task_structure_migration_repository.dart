/// 文件用途：仓储接口 - 任务结构迁移（note → description + subtasks）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

/// 待迁移的学习内容条目（仅包含迁移所需字段）。
class LegacyNoteMigrationItem {
  /// 构造函数。
  const LegacyNoteMigrationItem({
    required this.learningItemId,
    required this.note,
    required this.isMockData,
    this.existingDescription,
  });

  final int learningItemId;
  final String note;
  final bool isMockData;
  final String? existingDescription;
}

/// 任务结构迁移仓储接口。
///
/// 说明：
/// - 迁移属于“技术性数据变更”，需要事务与幂等保障
/// - 由数据层实现（可直接操作 Drift 并补齐同步日志）
abstract class TaskStructureMigrationRepository {
  /// 查询待迁移条目（仅返回 note 非空的记录）。
  ///
  /// 参数：
  /// - [limit] 每次拉取上限（用于分批迁移，避免一次性占用过多内存）
  Future<List<LegacyNoteMigrationItem>> getPendingLegacyNoteItems({
    int limit = 200,
  });

  /// 查询某学习内容下的现有子任务数量（用于幂等/中断恢复）。
  Future<int> getExistingSubtaskCount(int learningItemId);

  /// 对单条学习内容应用迁移（事务内）。
  ///
  /// 规则：
  /// - 仅在“子任务不存在”时才会插入 subtasks（避免中断重跑导致重复）
  /// - description 若已存在且非空，则不覆盖
  /// - 迁移成功后必须将 note 置空（作为幂等锚点）
  Future<void> applyMigrationForItem({
    required int learningItemId,
    required bool isMockData,
    required String? migratedDescription,
    required List<String> migratedSubtasks,
  });
}

