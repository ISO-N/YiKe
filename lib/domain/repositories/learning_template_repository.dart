/// 文件用途：仓储接口 - 学习模板（LearningTemplateRepository），用于快速模板（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import '../entities/learning_template.dart';

/// 学习模板仓储接口。
abstract class LearningTemplateRepository {
  /// 创建模板。
  Future<LearningTemplateEntity> create(LearningTemplateEntity template);

  /// 更新模板。
  Future<LearningTemplateEntity> update(LearningTemplateEntity template);

  /// 删除模板。
  Future<void> delete(int id);

  /// 根据 ID 获取模板。
  Future<LearningTemplateEntity?> getById(int id);

  /// 获取全部模板（按 sortOrder 排序）。
  Future<List<LearningTemplateEntity>> getAll();

  /// 检查模板名称是否已存在。
  Future<bool> existsName(String name, {int? exceptId});

  /// 批量更新排序字段。
  Future<void> updateSortOrders(Map<int, int> idToOrder);
}
