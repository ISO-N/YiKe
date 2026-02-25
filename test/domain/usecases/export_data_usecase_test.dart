// 文件用途：ExportDataUseCase 单元测试（F8：JSON/CSV 序列化与写文件）。
// 作者：Codex
// 创建日期：2026-02-25

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:yike/data/database/daos/learning_item_dao.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_item_repository_impl.dart';
import 'package:yike/data/repositories/review_task_repository_impl.dart';
import 'package:yike/domain/usecases/export_data_usecase.dart';

import '../../helpers/test_database.dart';

/// PathProviderPlatform 假实现：仅提供 documentsPath。
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  late AppDatabase db;
  late ExportDataUseCase useCase;

  setUp(() {
    db = createInMemoryDatabase();
    useCase = ExportDataUseCase(
      learningItemRepository: LearningItemRepositoryImpl(LearningItemDao(db)),
      reviewTaskRepository: ReviewTaskRepositoryImpl(dao: ReviewTaskDao(db)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem() async {
    return db
        .into(db.learningItems)
        .insert(
          LearningItemsCompanion.insert(
            title: 'T1',
            note: const drift.Value('N1'),
            tags: drift.Value(jsonEncode(['a', 'b'])),
            learningDate: DateTime(2026, 2, 25),
            createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
          ),
        );
  }

  Future<int> insertTask({required int itemId}) async {
    return db
        .into(db.reviewTasks)
        .insert(
          ReviewTasksCompanion.insert(
            learningItemId: itemId,
            reviewRound: 1,
            scheduledDate: DateTime(2026, 2, 26, 9),
            status: const drift.Value('done'),
            completedAt: drift.Value(DateTime(2026, 2, 26, 9)),
            createdAt: drift.Value(DateTime(2026, 2, 25, 9)),
          ),
        );
  }

  test('JSON 导出：文件生成且字段齐全', () async {
    final tmp = await Directory.systemTemp.createTemp('yike_export_test_');
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(tmp.path);

    try {
      final itemId = await insertItem();
      await insertTask(itemId: itemId);

      final result = await useCase.execute(
        const ExportParams(
          format: ExportFormat.json,
          includeItems: true,
          includeTasks: true,
        ),
      );

      expect(await result.file.exists(), true);
      expect(result.totalCount, 2);

      final json =
          jsonDecode(await result.file.readAsString()) as Map<String, Object?>;
      expect(json['version'], '2.0');
      expect((json['items'] as List).length, 1);
      expect((json['tasks'] as List).length, 1);
    } finally {
      PathProviderPlatform.instance = original;
    }
  });

  test('CSV 导出：包含学习内容与复习任务两个区域', () async {
    final tmp = await Directory.systemTemp.createTemp('yike_export_test_');
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(tmp.path);

    try {
      final itemId = await insertItem();
      await insertTask(itemId: itemId);

      final result = await useCase.execute(
        const ExportParams(
          format: ExportFormat.csv,
          includeItems: true,
          includeTasks: true,
        ),
      );

      final content = await result.file.readAsString();
      expect(content.contains('学习内容'), true);
      expect(content.contains('复习任务'), true);
      expect(
        content.contains('id,title,note,tags,learningDate,createdAt'),
        true,
      );
      expect(
        content.contains(
          'id,learningItemId,reviewRound,scheduledDate,status,completedAt,skippedAt,createdAt',
        ),
        true,
      );
    } finally {
      PathProviderPlatform.instance = original;
    }
  });
}
