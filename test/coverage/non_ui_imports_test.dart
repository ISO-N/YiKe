// 文件用途：非 UI 覆盖率辅助测试（通过 import 强制加载非 UI 源文件，避免覆盖率虚高）。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';

// core/utils
import 'package:yike/core/utils/date_utils.dart';
import 'package:yike/core/utils/ebbinghaus_utils.dart';
import 'package:yike/core/utils/time_utils.dart';

// domain
import 'package:yike/domain/entities/app_settings.dart';
import 'package:yike/domain/entities/learning_item.dart';
import 'package:yike/domain/entities/review_config.dart';
import 'package:yike/domain/entities/review_task.dart';
import 'package:yike/domain/entities/task_day_stats.dart';
import 'package:yike/domain/repositories/learning_item_repository.dart';
import 'package:yike/domain/repositories/review_task_repository.dart';
import 'package:yike/domain/repositories/settings_repository.dart';
import 'package:yike/domain/usecases/complete_review_task_usecase.dart';
import 'package:yike/domain/usecases/create_learning_item_usecase.dart';
import 'package:yike/domain/usecases/export_data_usecase.dart';
import 'package:yike/domain/usecases/get_calendar_tasks_usecase.dart';
import 'package:yike/domain/usecases/get_home_tasks_usecase.dart';
import 'package:yike/domain/usecases/get_statistics_usecase.dart';
import 'package:yike/domain/usecases/skip_review_task_usecase.dart';

// data
import 'package:yike/data/database/daos/learning_item_dao.dart';
import 'package:yike/data/database/daos/review_task_dao.dart';
import 'package:yike/data/database/daos/settings_dao.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/data/repositories/learning_item_repository_impl.dart';
import 'package:yike/data/repositories/review_task_repository_impl.dart';
import 'package:yike/data/repositories/settings_repository_impl.dart';

// infrastructure/storage
import 'package:yike/infrastructure/storage/secure_storage_service.dart';
import 'package:yike/infrastructure/storage/settings_crypto.dart';

void main() {
  test('覆盖率辅助：确保非 UI 库被加载', () {
    // 说明：不在此处写任何业务断言；该用例仅用于触发上述 import 对应文件进入覆盖率统计范围。
    expect(YikeDateUtils, isNotNull);
    expect(EbbinghausUtils, isNotNull);
    expect(TimeUtils, isNotNull);
    expect(AppSettingsEntity, isNotNull);
    expect(LearningItemEntity, isNotNull);
    expect(ReviewConfig, isNotNull);
    expect(ReviewTaskEntity, isNotNull);
    expect(TaskDayStats, isNotNull);
    expect(LearningItemRepository, isNotNull);
    expect(ReviewTaskRepository, isNotNull);
    expect(SettingsRepository, isNotNull);
    expect(CompleteReviewTaskUseCase, isNotNull);
    expect(CreateLearningItemUseCase, isNotNull);
    expect(ExportDataUseCase, isNotNull);
    expect(GetCalendarTasksUseCase, isNotNull);
    expect(GetHomeTasksUseCase, isNotNull);
    expect(GetStatisticsUseCase, isNotNull);
    expect(SkipReviewTaskUseCase, isNotNull);
    expect(LearningItemDao, isNotNull);
    expect(ReviewTaskDao, isNotNull);
    expect(SettingsDao, isNotNull);
    expect(AppDatabase, isNotNull);
    expect(LearningItemRepositoryImpl, isNotNull);
    expect(ReviewTaskRepositoryImpl, isNotNull);
    expect(SettingsRepositoryImpl, isNotNull);
    expect(SecureStorageService, isNotNull);
    expect(SettingsCrypto, isNotNull);
  });
}
