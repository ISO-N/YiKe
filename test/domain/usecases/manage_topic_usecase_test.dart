// 文件用途：ManageTopicUseCase 单元测试（校验、重复检测、关联操作透传）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/learning_topic.dart';
import 'package:yike/domain/entities/learning_topic_overview.dart';
import 'package:yike/domain/repositories/learning_topic_repository.dart';
import 'package:yike/domain/usecases/manage_topic_usecase.dart';

void main() {
  test('create/update: name 为空会抛 ArgumentError', () async {
    final usecase = ManageTopicUseCase(repository: _InMemoryTopicRepo());
    expect(() => usecase.create(const TopicParams(name: ' ')), throwsArgumentError);
    expect(
      () => usecase.update(1, const TopicParams(name: ' '), createdAt: DateTime(2026, 2, 26)),
      throwsArgumentError,
    );
  });

  test('create/update: 名称重复会抛 StateError（update 支持 exceptId）', () async {
    final repo = _InMemoryTopicRepo();
    final usecase = ManageTopicUseCase(repository: repo);

    final a = await usecase.create(const TopicParams(name: 'A'));
    expect(
      () => usecase.create(const TopicParams(name: 'A')),
      throwsStateError,
    );

    // update 自己不算重复。
    await usecase.update(a.id!, const TopicParams(name: 'A'), createdAt: a.createdAt);

    final b = await usecase.create(const TopicParams(name: 'B'));
    expect(
      () => usecase.update(a.id!, const TopicParams(name: 'B'), createdAt: a.createdAt),
      throwsStateError,
    );

    expect(b.id, isNotNull);
  });

  test('add/remove/get/delete: 透传到仓储并生效', () async {
    final repo = _InMemoryTopicRepo();
    final usecase = ManageTopicUseCase(repository: repo);

    final topic = await usecase.create(const TopicParams(name: 'T'));
    await usecase.addItemToTopic(topic.id!, 10);
    await usecase.addItemToTopic(topic.id!, 11);

    final byId = await usecase.getById(topic.id!);
    expect(byId, isNotNull);
    expect(byId!.itemIds, [10, 11]);

    await usecase.removeItemFromTopic(topic.id!, 10);
    final byId2 = await usecase.getById(topic.id!);
    expect(byId2!.itemIds, [11]);

    await usecase.delete(topic.id!);
    final byId3 = await usecase.getById(topic.id!);
    expect(byId3, isNull);
  });

  test('getAll/getOverviews: 返回列表', () async {
    final repo = _InMemoryTopicRepo();
    final usecase = ManageTopicUseCase(repository: repo);
    await usecase.create(const TopicParams(name: 'A'));
    await usecase.create(const TopicParams(name: 'B'));

    final all = await usecase.getAll();
    expect(all.length, 2);

    final overviews = await usecase.getOverviews();
    expect(overviews.length, 2);
    expect(overviews.every((e) => e.itemCount == 0), isTrue);
  });
}

class _InMemoryTopicRepo implements LearningTopicRepository {
  final Map<int, LearningTopicEntity> _store = {};
  final Map<int, List<int>> _topicItems = {};
  int _nextId = 1;

  @override
  Future<LearningTopicEntity> create(LearningTopicEntity topic) async {
    final id = _nextId++;
    final saved = topic.copyWith(id: id);
    _store[id] = saved;
    _topicItems[id] = <int>[];
    return saved;
  }

  @override
  Future<void> delete(int id) async {
    _store.remove(id);
    _topicItems.remove(id);
  }

  @override
  Future<LearningTopicEntity?> getById(int id) async {
    final topic = _store[id];
    if (topic == null) return null;
    final items = List<int>.from(_topicItems[id] ?? const <int>[]);
    return topic.copyWith(itemIds: items);
  }

  @override
  Future<List<LearningTopicEntity>> getAll() async {
    final ids = _store.keys.toList()..sort();
    final list = <LearningTopicEntity>[];
    for (final id in ids) {
      final topic = await getById(id);
      if (topic != null) list.add(topic);
    }
    return list;
  }

  @override
  Future<List<LearningTopicOverviewEntity>> getOverviews() async {
    final all = await getAll();
    return all
        .map(
          (t) => LearningTopicOverviewEntity(
            topic: t.copyWith(itemIds: const []),
            itemCount: 0,
            completedCount: 0,
            totalCount: 0,
          ),
        )
        .toList();
  }

  @override
  Future<LearningTopicEntity> update(LearningTopicEntity topic) async {
    final id = topic.id;
    if (id == null) throw ArgumentError('id 不能为空');
    if (!_store.containsKey(id)) throw StateError('不存在');
    _store[id] = topic;
    return topic;
  }

  @override
  Future<void> addItemToTopic(int topicId, int learningItemId) async {
    final list = _topicItems.putIfAbsent(topicId, () => <int>[]);
    if (!list.contains(learningItemId)) list.add(learningItemId);
  }

  @override
  Future<void> removeItemFromTopic(int topicId, int learningItemId) async {
    _topicItems[topicId]?.remove(learningItemId);
  }

  @override
  Future<List<int>> getItemIdsByTopicId(int topicId) async {
    return List<int>.from(_topicItems[topicId] ?? const <int>[]);
  }

  @override
  Future<bool> existsName(String name, {int? exceptId}) async {
    final trimmed = name.trim();
    return _store.values.any(
      (e) => e.name.trim() == trimmed && (exceptId == null || e.id != exceptId),
    );
  }
}

