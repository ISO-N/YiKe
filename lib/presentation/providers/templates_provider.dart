/// 文件用途：模板状态管理（Riverpod StateNotifier），用于模板 CRUD 与排序（F1.2）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/entities/learning_template.dart';
import '../../domain/usecases/manage_template_usecase.dart';

/// 模板列表状态。
class TemplatesState {
  const TemplatesState({
    required this.isLoading,
    required this.templates,
    this.errorMessage,
  });

  final bool isLoading;
  final List<LearningTemplateEntity> templates;
  final String? errorMessage;

  factory TemplatesState.initial() =>
      const TemplatesState(isLoading: true, templates: []);

  TemplatesState copyWith({
    bool? isLoading,
    List<LearningTemplateEntity>? templates,
    String? errorMessage,
  }) {
    return TemplatesState(
      isLoading: isLoading ?? this.isLoading,
      templates: templates ?? this.templates,
      errorMessage: errorMessage,
    );
  }
}

/// 模板 Notifier。
class TemplatesNotifier extends StateNotifier<TemplatesState> {
  TemplatesNotifier(this._useCase) : super(TemplatesState.initial());

  final ManageTemplateUseCase _useCase;

  /// 加载模板列表。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _useCase.getAll();
      state = state.copyWith(isLoading: false, templates: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 创建模板。
  Future<void> create(TemplateParams params) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _useCase.create(params);
      final list = await _useCase.getAll();
      state = state.copyWith(isLoading: false, templates: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// 更新模板。
  Future<void> update(
    LearningTemplateEntity template,
    TemplateParams params,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _useCase.update(
        template.id!,
        params,
        createdAt: template.createdAt,
      );
      final list = await _useCase.getAll();
      state = state.copyWith(isLoading: false, templates: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// 删除模板。
  Future<void> delete(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _useCase.delete(id);
      final list = await _useCase.getAll();
      state = state.copyWith(isLoading: false, templates: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// 更新排序（以当前列表顺序为准）。
  Future<void> reorder(List<LearningTemplateEntity> ordered) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final map = <int, int>{};
      for (var i = 0; i < ordered.length; i++) {
        final id = ordered[i].id;
        if (id == null) continue;
        map[id] = i;
      }
      await _useCase.updateSortOrders(map);
      final list = await _useCase.getAll();
      state = state.copyWith(isLoading: false, templates: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

/// 模板 Provider。
final templatesProvider =
    StateNotifierProvider<TemplatesNotifier, TemplatesState>((ref) {
      final useCase = ref.read(manageTemplateUseCaseProvider);
      final notifier = TemplatesNotifier(useCase);
      notifier.load();
      return notifier;
    });
