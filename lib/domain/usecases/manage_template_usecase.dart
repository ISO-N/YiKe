/// 文件用途：用例 - 管理学习模板（ManageTemplateUseCase），包含占位符替换（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import '../entities/learning_template.dart';
import '../repositories/learning_template_repository.dart';

/// 模板创建/更新参数。
class TemplateParams {
  /// 构造函数。
  const TemplateParams({
    required this.name,
    required this.titlePattern,
    this.notePattern,
    required this.tags,
    this.sortOrder = 0,
  });

  final String name;
  final String titlePattern;
  final String? notePattern;
  final List<String> tags;
  final int sortOrder;
}

/// 学习模板管理用例。
class ManageTemplateUseCase {
  /// 构造函数。
  const ManageTemplateUseCase({required LearningTemplateRepository repository})
    : _repository = repository;

  final LearningTemplateRepository _repository;

  /// 创建模板。
  ///
  /// 异常：
  /// - 当模板名称或标题模板为空时抛出 [ArgumentError]
  /// - 当模板名称重复时抛出 [StateError]
  Future<LearningTemplateEntity> create(TemplateParams params) async {
    final name = params.name.trim();
    final titlePattern = params.titlePattern.trim();
    if (name.isEmpty) throw ArgumentError('模板名称不能为空');
    if (titlePattern.isEmpty) throw ArgumentError('标题模板不能为空');

    final exists = await _repository.existsName(name);
    if (exists) {
      throw StateError('模板名称已存在');
    }

    final now = DateTime.now();
    final entity = LearningTemplateEntity(
      name: name,
      titlePattern: titlePattern,
      notePattern: params.notePattern?.trim().isEmpty == true
          ? null
          : params.notePattern?.trim(),
      tags: params.tags,
      sortOrder: params.sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.create(entity);
  }

  /// 更新模板。
  Future<LearningTemplateEntity> update(
    int id,
    TemplateParams params, {
    required DateTime createdAt,
  }) async {
    final name = params.name.trim();
    final titlePattern = params.titlePattern.trim();
    if (name.isEmpty) throw ArgumentError('模板名称不能为空');
    if (titlePattern.isEmpty) throw ArgumentError('标题模板不能为空');

    final exists = await _repository.existsName(name, exceptId: id);
    if (exists) {
      throw StateError('模板名称已存在');
    }

    final now = DateTime.now();
    final entity = LearningTemplateEntity(
      id: id,
      name: name,
      titlePattern: titlePattern,
      notePattern: params.notePattern?.trim().isEmpty == true
          ? null
          : params.notePattern?.trim(),
      tags: params.tags,
      sortOrder: params.sortOrder,
      createdAt: createdAt,
      updatedAt: now,
    );
    return _repository.update(entity);
  }

  /// 删除模板。
  Future<void> delete(int id) => _repository.delete(id);

  /// 获取全部模板。
  Future<List<LearningTemplateEntity>> getAll() => _repository.getAll();

  /// 批量更新排序。
  Future<void> updateSortOrders(Map<int, int> idToOrder) =>
      _repository.updateSortOrders(idToOrder);

  /// 应用模板（替换占位符）。
  ///
  /// 规则：
  /// - {date}：yyyy-MM-dd
  /// - {day}：yyyy-M-d（不含前导 0）
  /// - {weekday}：周一..周日
  /// - 未知占位符保持原样
  Map<String, String> applyTemplate(
    LearningTemplateEntity template, {
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final dateText = '${y.toString().padLeft(4, '0')}-'
        '${m.toString().padLeft(2, '0')}-'
        '${d.toString().padLeft(2, '0')}';
    final dayText = '$y-$m-$d';
    final weekdayText = _weekdayZh(date.weekday);

    String replace(String input) {
      return input
          .replaceAll('{date}', dateText)
          .replaceAll('{day}', dayText)
          .replaceAll('{weekday}', weekdayText);
    }

    final title = replace(template.titlePattern);
    final note = template.notePattern == null ? '' : replace(template.notePattern!);
    return {'title': title, 'note': note};
  }

  String _weekdayZh(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '周一';
      case DateTime.tuesday:
        return '周二';
      case DateTime.wednesday:
        return '周三';
      case DateTime.thursday:
        return '周四';
      case DateTime.friday:
        return '周五';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
      default:
        return '周?';
    }
  }
}

