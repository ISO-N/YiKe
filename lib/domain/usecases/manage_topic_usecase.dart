/// 文件用途：用例 - 管理学习主题（ManageTopicUseCase），包含主题 CRUD 与关联操作（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:uuid/uuid.dart';

import '../entities/learning_topic.dart';
import '../entities/learning_topic_overview.dart';
import '../repositories/learning_topic_repository.dart';

/// 主题创建/更新参数。
class TopicParams {
  /// 构造函数。
  const TopicParams({required this.name, this.description});

  final String name;
  final String? description;
}

/// 学习主题管理用例。
class ManageTopicUseCase {
  /// 构造函数。
  const ManageTopicUseCase({required LearningTopicRepository repository})
    : _repository = repository;

  final LearningTopicRepository _repository;

  static const Uuid _uuid = Uuid();

  /// 创建主题。
  ///
  /// 异常：
  /// - 当主题名称为空时抛出 [ArgumentError]
  /// - 当主题名称重复时抛出 [StateError]
  Future<LearningTopicEntity> create(TopicParams params) async {
    final name = params.name.trim();
    if (name.isEmpty) throw ArgumentError('主题名称不能为空');
    final exists = await _repository.existsName(name);
    if (exists) throw StateError('主题名称已存在');

    final now = DateTime.now();
    final entity = LearningTopicEntity(
      uuid: _uuid.v4(),
      name: name,
      description: params.description?.trim().isEmpty == true
          ? null
          : params.description?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    return _repository.create(entity);
  }

  /// 更新主题。
  Future<LearningTopicEntity> update(
    int id,
    TopicParams params, {
    required DateTime createdAt,
    required String uuid,
  }) async {
    final name = params.name.trim();
    if (name.isEmpty) throw ArgumentError('主题名称不能为空');
    final exists = await _repository.existsName(name, exceptId: id);
    if (exists) throw StateError('主题名称已存在');

    final now = DateTime.now();
    final entity = LearningTopicEntity(
      id: id,
      uuid: uuid,
      name: name,
      description: params.description?.trim().isEmpty == true
          ? null
          : params.description?.trim(),
      createdAt: createdAt,
      updatedAt: now,
    );
    return _repository.update(entity);
  }

  /// 删除主题（仅解除关联）。
  Future<void> delete(int id) => _repository.delete(id);

  /// 获取主题详情（包含 itemIds）。
  Future<LearningTopicEntity?> getById(int id) => _repository.getById(id);

  /// 获取全部主题（包含 itemIds）。
  Future<List<LearningTopicEntity>> getAll() => _repository.getAll();

  /// 获取主题概览。
  Future<List<LearningTopicOverviewEntity>> getOverviews() =>
      _repository.getOverviews();

  /// 关联学习内容到主题。
  Future<void> addItemToTopic(int topicId, int learningItemId) =>
      _repository.addItemToTopic(topicId, learningItemId);

  /// 从主题移除学习内容。
  Future<void> removeItemFromTopic(int topicId, int learningItemId) =>
      _repository.removeItemFromTopic(topicId, learningItemId);
}
