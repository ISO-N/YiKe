/// 文件用途：Drift 表定义 - 学习子任务表（learning_subtasks）。
/// 作者：Codex
/// 创建日期：2026-03-01
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'learning_items_table.dart';

/// 学习子任务表。
///
/// 说明：
/// - 用于承载“任务描述拆分出的清单”与用户手动维护的子任务列表
/// - 只提供清单能力（增删改排序），不实现子任务完成态（见 spec）
@TableIndex(
  name: 'idx_learning_subtasks_item_order',
  columns: {#learningItemId, #sortOrder},
)
class LearningSubtasks extends Table {
  /// 主键 ID。
  IntColumn get id => integer().autoIncrement()();

  /// 业务唯一标识（UUID v4）。
  ///
  /// 说明：
  /// - 用于备份合并去重、跨设备映射的稳定 key
  /// - 插入时自动生成，避免空字符串触发唯一约束冲突
  TextColumn get uuid =>
      text()
          .withLength(min: 1, max: 36)
          .clientDefault(() => const Uuid().v4())();

  /// 外键：关联的学习内容 ID（删除学习内容时级联删除）。
  IntColumn get learningItemId =>
      integer().references(LearningItems, #id, onDelete: KeyAction.cascade)();

  /// 子任务内容（必填）。
  TextColumn get content => text().withLength(min: 1, max: 500)();

  /// 排序顺序（同一 learningItemId 内从 0 开始递增）。
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  /// 更新时间（可空）。
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();

  /// 是否为模拟数据（用于 Debug 生成/清理、同步/导出隔离）。
  BoolColumn get isMockData =>
      boolean().named('is_mock_data').withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {uuid},
  ];
}

