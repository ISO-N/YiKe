/// 文件用途：依赖注入 Provider 集合（数据库/DAO/Repository/UseCase/Service）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/daos/learning_item_dao.dart';
import '../data/database/daos/learning_template_dao.dart';
import '../data/database/daos/learning_topic_dao.dart';
import '../data/database/daos/review_task_dao.dart';
import '../data/database/daos/settings_dao.dart';
import '../data/database/database.dart';
import '../data/repositories/learning_item_repository_impl.dart';
import '../data/repositories/learning_template_repository_impl.dart';
import '../data/repositories/learning_topic_repository_impl.dart';
import '../data/repositories/review_task_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../domain/repositories/learning_item_repository.dart';
import '../domain/repositories/learning_template_repository.dart';
import '../domain/repositories/learning_topic_repository.dart';
import '../domain/repositories/review_task_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/ocr_service.dart';
import '../infrastructure/storage/secure_storage_service.dart';
import '../domain/usecases/complete_review_task_usecase.dart';
import '../domain/usecases/create_learning_item_usecase.dart';
import '../domain/usecases/export_data_usecase.dart';
import '../domain/usecases/get_calendar_tasks_usecase.dart';
import '../domain/usecases/get_home_tasks_usecase.dart';
import '../domain/usecases/get_statistics_usecase.dart';
import '../domain/usecases/import_learning_items_usecase.dart';
import '../domain/usecases/manage_template_usecase.dart';
import '../domain/usecases/manage_topic_usecase.dart';
import '../domain/usecases/ocr_recognition_usecase.dart';
import '../domain/usecases/skip_review_task_usecase.dart';
import '../infrastructure/ocr/ocr_service.dart' as infra_ocr;
import '../infrastructure/speech/speech_service.dart';

/// 数据库 Provider（需要在启动时 override 注入真实实例）。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider 必须在启动时被 override 注入。');
});

/// DAO Providers
final learningItemDaoProvider = Provider<LearningItemDao>((ref) {
  return LearningItemDao(ref.read(appDatabaseProvider));
});

final reviewTaskDaoProvider = Provider<ReviewTaskDao>((ref) {
  return ReviewTaskDao(ref.read(appDatabaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.read(appDatabaseProvider));
});

final learningTemplateDaoProvider = Provider<LearningTemplateDao>((ref) {
  return LearningTemplateDao(ref.read(appDatabaseProvider));
});

final learningTopicDaoProvider = Provider<LearningTopicDao>((ref) {
  return LearningTopicDao(ref.read(appDatabaseProvider));
});

/// 基础设施 Providers
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return const infra_ocr.MlKitOcrService();
});

/// Repository Providers
final learningItemRepositoryProvider = Provider<LearningItemRepository>((ref) {
  return LearningItemRepositoryImpl(ref.read(learningItemDaoProvider));
});

final learningTemplateRepositoryProvider = Provider<LearningTemplateRepository>((
  ref,
) {
  return LearningTemplateRepositoryImpl(ref.read(learningTemplateDaoProvider));
});

final learningTopicRepositoryProvider = Provider<LearningTopicRepository>((ref) {
  return LearningTopicRepositoryImpl(ref.read(learningTopicDaoProvider));
});

final reviewTaskRepositoryProvider = Provider<ReviewTaskRepository>((ref) {
  return ReviewTaskRepositoryImpl(dao: ref.read(reviewTaskDaoProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    dao: ref.read(settingsDaoProvider),
    secureStorageService: ref.read(secureStorageServiceProvider),
  );
});

/// UseCase Providers
final createLearningItemUseCaseProvider = Provider<CreateLearningItemUseCase>((
  ref,
) {
  return CreateLearningItemUseCase(
    learningItemRepository: ref.read(learningItemRepositoryProvider),
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
  );
});

final importLearningItemsUseCaseProvider = Provider<ImportLearningItemsUseCase>((
  ref,
) {
  return ImportLearningItemsUseCase(create: ref.read(createLearningItemUseCaseProvider));
});

final manageTemplateUseCaseProvider = Provider<ManageTemplateUseCase>((ref) {
  return ManageTemplateUseCase(
    repository: ref.read(learningTemplateRepositoryProvider),
  );
});

final manageTopicUseCaseProvider = Provider<ManageTopicUseCase>((ref) {
  return ManageTopicUseCase(repository: ref.read(learningTopicRepositoryProvider));
});

final ocrRecognitionUseCaseProvider = Provider<OcrRecognitionUseCase>((ref) {
  return OcrRecognitionUseCase(ocrService: ref.read(ocrServiceProvider));
});

final getHomeTasksUseCaseProvider = Provider<GetHomeTasksUseCase>((ref) {
  return GetHomeTasksUseCase(
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
  );
});

final completeReviewTaskUseCaseProvider = Provider<CompleteReviewTaskUseCase>((
  ref,
) {
  return CompleteReviewTaskUseCase(
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
  );
});

final skipReviewTaskUseCaseProvider = Provider<SkipReviewTaskUseCase>((ref) {
  return SkipReviewTaskUseCase(
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
  );
});

/// v2.0 UseCase Providers
final getCalendarTasksUseCaseProvider = Provider<GetCalendarTasksUseCase>((
  ref,
) {
  return GetCalendarTasksUseCase(
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
  );
});

final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  return GetStatisticsUseCase(
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
    learningItemRepository: ref.read(learningItemRepositoryProvider),
  );
});

final exportDataUseCaseProvider = Provider<ExportDataUseCase>((ref) {
  return ExportDataUseCase(
    learningItemRepository: ref.read(learningItemRepositoryProvider),
    reviewTaskRepository: ref.read(reviewTaskRepositoryProvider),
  );
});
