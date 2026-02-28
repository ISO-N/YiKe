/// 文件用途：领域实体 - 复习任务（ReviewTask）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

/// 复习任务状态。
enum ReviewTaskStatus {
  /// 待复习。
  pending,

  /// 已完成。
  done,

  /// 已跳过。
  skipped,
}

extension ReviewTaskStatusX on ReviewTaskStatus {
  /// 转为数据库存储字符串。
  String toDbValue() {
    switch (this) {
      case ReviewTaskStatus.pending:
        return 'pending';
      case ReviewTaskStatus.done:
        return 'done';
      case ReviewTaskStatus.skipped:
        return 'skipped';
    }
  }

  /// 从数据库字符串解析。
  static ReviewTaskStatus fromDbValue(String value) {
    switch (value) {
      case 'done':
        return ReviewTaskStatus.done;
      case 'skipped':
        return ReviewTaskStatus.skipped;
      case 'pending':
      default:
        return ReviewTaskStatus.pending;
    }
  }
}

/// 复习任务实体（领域层）。
class ReviewTaskEntity {
  /// 构造函数。
  ///
  /// 参数：
  /// - [uuid] 业务唯一标识（用于备份合并去重，稳定且跨设备）
  /// - [id] 数据库 ID（新建时可为 null）
  /// - [learningItemId] 关联学习内容 ID
  /// - [reviewRound] 复习轮次（1-10）
  /// - [scheduledDate] 计划日期
  /// - [status] 当前状态
  /// - [completedAt] 完成时间
  /// - [skippedAt] 跳过时间
  /// - [createdAt] 创建时间
  const ReviewTaskEntity({
    required this.uuid,
    this.id,
    required this.learningItemId,
    required this.reviewRound,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
    this.skippedAt,
    required this.createdAt,
    this.isMockData = false,
  });

  /// 业务唯一标识（UUID v4）。
  ///
  /// 说明：
  /// - 用于备份/恢复的合并去重与外键修复（uuid → id 映射）
  /// - 不参与 UI 展示
  final String uuid;

  final int? id;
  final int learningItemId;
  final int reviewRound;
  final DateTime scheduledDate;
  final ReviewTaskStatus status;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final DateTime createdAt;

  /// 是否为模拟数据（v3.1：用于 Debug 模拟数据隔离）。
  final bool isMockData;

  ReviewTaskEntity copyWith({
    String? uuid,
    int? id,
    int? learningItemId,
    int? reviewRound,
    DateTime? scheduledDate,
    ReviewTaskStatus? status,
    DateTime? completedAt,
    DateTime? skippedAt,
    DateTime? createdAt,
    bool? isMockData,
  }) {
    return ReviewTaskEntity(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      learningItemId: learningItemId ?? this.learningItemId,
      reviewRound: reviewRound ?? this.reviewRound,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      createdAt: createdAt ?? this.createdAt,
      isMockData: isMockData ?? this.isMockData,
    );
  }
}

/// 首页展示用的复习任务视图实体（包含学习内容标题/备注等）。
///
/// 说明：领域层提供一个“只读视图”，避免展示层直接依赖数据层 join 结构。
class ReviewTaskViewEntity {
  /// 构造函数。
  const ReviewTaskViewEntity({
    required this.taskId,
    required this.learningItemId,
    required this.title,
    required this.note,
    required this.tags,
    required this.reviewRound,
    required this.scheduledDate,
    required this.status,
    required this.completedAt,
    required this.skippedAt,
    required this.isDeleted,
    required this.deletedAt,
  });

  final int taskId;
  final int learningItemId;
  final String title;
  final String? note;
  final List<String> tags;
  final int reviewRound;
  final DateTime scheduledDate;
  final ReviewTaskStatus status;
  final DateTime? completedAt;
  final DateTime? skippedAt;

  /// 学习内容是否已停用（软删除）。
  ///
  /// 说明：用于详情页只读模式与操作禁用判断。
  final bool isDeleted;

  /// 学习内容停用时间（可空）。
  final DateTime? deletedAt;
}
