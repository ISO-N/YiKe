/// 文件用途：仓储接口 - 学习内容（LearningItemRepository）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import '../entities/learning_item.dart';

/// 学习内容仓储接口。
abstract class LearningItemRepository {
  /// 创建学习内容。
  ///
  /// 返回值：保存后的实体（包含 id）。
  /// 异常：持久化失败时可能抛出异常。
  Future<LearningItemEntity> create(LearningItemEntity item);

  /// 更新学习内容。
  Future<LearningItemEntity> update(LearningItemEntity item);

  /// 更新学习内容备注（仅更新 note 字段）。
  ///
  /// 说明：用于任务详情中的“编辑备注”。
  Future<void> updateNote({required int id, required String? note});

  /// 停用学习内容（软删除）。
  ///
  /// 说明：设置 isDeleted=true 并写入 deletedAt，不物理删除数据。
  Future<void> deactivate(int id);

  /// 删除学习内容。
  Future<void> delete(int id);

  /// 根据 ID 获取学习内容。
  Future<LearningItemEntity?> getById(int id);

  /// 获取所有学习内容。
  Future<List<LearningItemEntity>> getAll();

  /// 按日期获取学习内容。
  Future<List<LearningItemEntity>> getByDate(DateTime date);

  /// 按标签获取学习内容。
  Future<List<LearningItemEntity>> getByTag(String tag);

  /// 获取所有标签（去重）。
  Future<List<String>> getAllTags();

  /// F7：获取标签分布（用于统计饼图）。
  ///
  /// 返回值：Map（key=tag，value=count，不保证排序）。
  Future<Map<String, int>> getTagDistribution();
}
