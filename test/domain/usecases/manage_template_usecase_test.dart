// 文件用途：ManageTemplateUseCase 单元测试（校验、重复检测、占位符替换、排序更新透传）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/entities/learning_template.dart';
import 'package:yike/domain/repositories/learning_template_repository.dart';
import 'package:yike/domain/usecases/manage_template_usecase.dart';

void main() {
  test('create: name/titlePattern 为空会抛 ArgumentError', () async {
    final usecase = ManageTemplateUseCase(repository: _InMemoryTemplateRepo());
    expect(
      () => usecase.create(
        const TemplateParams(name: ' ', titlePattern: 't', tags: []),
      ),
      throwsArgumentError,
    );
    expect(
      () => usecase.create(
        const TemplateParams(name: 'n', titlePattern: ' ', tags: []),
      ),
      throwsArgumentError,
    );
  });

  test('create/update: 名称重复会抛 StateError（update 支持 exceptId）', () async {
    final repo = _InMemoryTemplateRepo();
    final usecase = ManageTemplateUseCase(repository: repo);

    final a = await usecase.create(
      const TemplateParams(name: 'A', titlePattern: '{date}', tags: []),
    );

    expect(
      () => usecase.create(
        const TemplateParams(name: 'A', titlePattern: '{date}', tags: []),
      ),
      throwsStateError,
    );

    // update 自己不算重复；但更新为其他已存在名称算重复。
    await usecase.update(
      a.id!,
      const TemplateParams(name: 'A', titlePattern: '{date}', tags: []),
      createdAt: a.createdAt,
    );

    final b = await usecase.create(
      const TemplateParams(name: 'B', titlePattern: '{date}', tags: []),
    );
    expect(
      () => usecase.update(
        a.id!,
        const TemplateParams(name: 'B', titlePattern: '{date}', tags: []),
        createdAt: a.createdAt,
      ),
      throwsStateError,
    );

    // 规避 unused 警告：确保 b 被使用。
    expect(b.id, isNotNull);
  });

  test('applyTemplate: {date}/{day}/{weekday} 可替换，未知占位符保持原样', () {
    final usecase = ManageTemplateUseCase(repository: _InMemoryTemplateRepo());
    final template = LearningTemplateEntity(
      id: 1,
      name: 'T',
      titlePattern: '{date} {day} {weekday} {unknown}',
      notePattern: '{weekday}',
      tags: const [],
      createdAt: DateTime(2026, 2, 26),
    );

    final monday = DateTime(2026, 2, 23); // 2026-02-23 是周一
    expect(monday.weekday, DateTime.monday);

    final out = usecase.applyTemplate(template, now: monday);
    expect(out['title'], '2026-02-23 2026-2-23 周一 {unknown}');
    expect(out['note'], '周一');
  });

  test('getAll / updateSortOrders / delete: 透传到仓储', () async {
    final repo = _InMemoryTemplateRepo();
    final usecase = ManageTemplateUseCase(repository: repo);

    final a = await usecase.create(
      const TemplateParams(name: 'A', titlePattern: 'a', tags: [], sortOrder: 2),
    );
    final b = await usecase.create(
      const TemplateParams(name: 'B', titlePattern: 'b', tags: [], sortOrder: 1),
    );

    final all1 = await usecase.getAll();
    // 说明：仓储约定按 sortOrder 升序排序。
    expect(all1.map((e) => e.id).toList(), [b.id, a.id]);

    await usecase.updateSortOrders({a.id!: 0, b.id!: 3});
    final all2 = await usecase.getAll();
    expect(all2.map((e) => e.id).toList(), [a.id, b.id]);
    expect(all2.first.sortOrder, 0);
    expect(all2.last.sortOrder, 3);

    await usecase.delete(a.id!);
    final all3 = await usecase.getAll();
    expect(all3.map((e) => e.id).toList(), [b.id]);
  });
}

class _InMemoryTemplateRepo implements LearningTemplateRepository {
  final Map<int, LearningTemplateEntity> _store = {};
  int _nextId = 1;

  @override
  Future<LearningTemplateEntity> create(LearningTemplateEntity template) async {
    final id = _nextId++;
    final saved = template.copyWith(id: id);
    _store[id] = saved;
    return saved;
  }

  @override
  Future<void> delete(int id) async {
    _store.remove(id);
  }

  @override
  Future<List<LearningTemplateEntity>> getAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<LearningTemplateEntity?> getById(int id) async {
    return _store[id];
  }

  @override
  Future<LearningTemplateEntity> update(LearningTemplateEntity template) async {
    final id = template.id;
    if (id == null) throw ArgumentError('id 不能为空');
    if (!_store.containsKey(id)) throw StateError('不存在');
    _store[id] = template;
    return template;
  }

  @override
  Future<bool> existsName(String name, {int? exceptId}) async {
    final trimmed = name.trim();
    return _store.values.any(
      (e) => e.name.trim() == trimmed && (exceptId == null || e.id != exceptId),
    );
  }

  @override
  Future<void> updateSortOrders(Map<int, int> idToOrder) async {
    for (final entry in idToOrder.entries) {
      final existing = _store[entry.key];
      if (existing == null) continue;
      _store[entry.key] = existing.copyWith(sortOrder: entry.value);
    }
  }
}
