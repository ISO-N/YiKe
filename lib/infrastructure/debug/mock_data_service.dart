/// 文件用途：Debug 模拟数据服务（v3.1），用于一键生成/清理学习内容与复习任务。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../data/database/daos/learning_item_dao.dart';
import '../../data/database/daos/review_task_dao.dart';
import '../../data/database/database.dart';

/// 模拟数据模板。
enum MockDataTemplate {
  /// 随机混合（英语单词/历史事件/自定义）。
  random,

  /// 英语单词模板。
  englishWords,

  /// 历史事件模板。
  historyEvents,

  /// 自定义模板（使用 [MockDataConfig.customPrefix]）。
  custom,
}

/// 模拟数据生成配置。
class MockDataConfig {
  const MockDataConfig({
    this.contentCount = 10,
    this.taskCount = 50,
    this.daysRange = 30,
    this.template = MockDataTemplate.random,
    this.customPrefix = '自定义',
  });

  /// 学习内容数量（1-100）。
  final int contentCount;

  /// 复习任务数量（1-500）。
  final int taskCount;

  /// 复习日期范围：最近 N 天（7/14/30/60/90）。
  final int daysRange;

  /// 生成模板。
  final MockDataTemplate template;

  /// 自定义模板前缀。
  final String customPrefix;
}

/// 模拟数据生成结果。
class MockDataGenerateResult {
  const MockDataGenerateResult({
    required this.insertedItemCount,
    required this.insertedTaskCount,
  });

  final int insertedItemCount;
  final int insertedTaskCount;
}

/// Debug 模拟数据服务。
///
/// 说明：
/// - 仅 Debug 模式下可用（release 下调用会抛出异常）
/// - 生成的数据统一标记 isMockData=true，便于隔离同步/导出与一键清理
class MockDataService {
  MockDataService({
    required this.db,
    required LearningItemDao learningItemDao,
    required ReviewTaskDao reviewTaskDao,
  }) : _learningItemDao = learningItemDao,
       _reviewTaskDao = reviewTaskDao,
       _random = Random();

  final AppDatabase db;
  final LearningItemDao _learningItemDao;
  final ReviewTaskDao _reviewTaskDao;
  final Random _random;

  static const _intervalByRound = <int, int>{1: 1, 2: 2, 3: 4, 4: 7, 5: 15};

  /// 生成模拟数据（学习内容 + 复习任务）。
  ///
  /// 返回值：生成结果（插入条数）。
  /// 异常：
  /// - 非 Debug 模式下调用会抛出 [StateError]
  /// - 参数不合法时抛出 [ArgumentError]
  Future<MockDataGenerateResult> generate(MockDataConfig config) async {
    if (!kDebugMode) {
      throw StateError('MockDataService 仅允许在 Debug 模式下使用');
    }
    _validateConfig(config);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 复习日期范围：最近 N 天（包含今天）。
    final scheduledStart = todayStart.subtract(
      Duration(days: config.daysRange - 1),
    );
    final scheduledEndExclusive = todayStart.add(const Duration(days: 1));

    // 为了让 scheduledDate = learningDate + interval 仍能落在范围内，
    // learningDate 的随机范围需要向前扩展 maxInterval（15 天）。
    final earliestLearningDay = scheduledStart.subtract(
      const Duration(days: 15),
    );
    final latestLearningDay = scheduledEndExclusive.subtract(
      const Duration(days: 1),
    );

    final items = <({int id, DateTime learningDay})>[];

    return db.transaction(() async {
      // 1) 插入学习内容（数量较少，逐条插入便于获取 ID）。
      for (var i = 0; i < config.contentCount; i++) {
        final learningDay = _randomDay(
          start: earliestLearningDay,
          endInclusive: latestLearningDay,
        );
        final title = _mockTitle(config: config, index: i);
        final note = _mockNote(learningDay: learningDay, now: now);

        final id = await _learningItemDao.insertLearningItem(
          LearningItemsCompanion.insert(
            title: title,
            note: Value(note),
            tags: const Value('[]'),
            learningDate: learningDay,
            createdAt: Value(now),
            updatedAt: const Value.absent(),
            isMockData: const Value(true),
          ),
        );
        items.add((id: id, learningDay: learningDay));
      }

      // 2) 插入复习任务（批量插入提升性能）。
      final companions = <ReviewTasksCompanion>[];
      final maxAttempts = config.taskCount * 25;

      for (
        var attempt = 0;
        attempt < maxAttempts && companions.length < config.taskCount;
        attempt++
      ) {
        final item = items[_random.nextInt(items.length)];
        final round = _pickRoundByWeight();
        final intervalDays = _intervalByRound[round]!;

        // scheduledDate 由 learningDay + interval 推导，保证“轮次-间隔”语义一致。
        final scheduledDay = DateTime(
          item.learningDay.year,
          item.learningDay.month,
          item.learningDay.day,
        ).add(Duration(days: intervalDays));

        // 只保留落在“最近 N 天”范围内的任务。
        if (scheduledDay.isBefore(scheduledStart) ||
            !scheduledDay.isBefore(scheduledEndExclusive)) {
          continue;
        }

        final scheduledAt = _withRandomTime(scheduledDay);
        final status = _pickStatus(scheduledAt: scheduledAt, now: now);

        final (completedAt, skippedAt) = _statusTimestamps(
          status: status,
          scheduledAt: scheduledAt,
        );

        companions.add(
          ReviewTasksCompanion.insert(
            learningItemId: item.id,
            reviewRound: round,
            scheduledDate: scheduledAt,
            status: Value(status),
            completedAt: Value(completedAt),
            skippedAt: Value(skippedAt),
            createdAt: Value(now),
            updatedAt: const Value.absent(),
            isMockData: const Value(true),
          ),
        );
      }

      // 兜底：若由于随机分布导致数量不足，则用“范围内随机日期”补齐（仍保持 round 范围合法）。
      while (companions.length < config.taskCount) {
        final item = items[_random.nextInt(items.length)];
        final round = _pickRoundByWeight();
        final scheduledDay = _randomDay(
          start: scheduledStart,
          endInclusive: scheduledEndExclusive.subtract(const Duration(days: 1)),
        );
        final scheduledAt = _withRandomTime(scheduledDay);
        final status = _pickStatus(scheduledAt: scheduledAt, now: now);
        final (completedAt, skippedAt) = _statusTimestamps(
          status: status,
          scheduledAt: scheduledAt,
        );

        companions.add(
          ReviewTasksCompanion.insert(
            learningItemId: item.id,
            reviewRound: round,
            scheduledDate: scheduledAt,
            status: Value(status),
            completedAt: Value(completedAt),
            skippedAt: Value(skippedAt),
            createdAt: Value(now),
            updatedAt: const Value.absent(),
            isMockData: const Value(true),
          ),
        );
      }

      await _reviewTaskDao.insertReviewTasks(companions);

      return MockDataGenerateResult(
        insertedItemCount: items.length,
        insertedTaskCount: companions.length,
      );
    });
  }

  /// 清理所有模拟数据（按 isMockData=true）。
  ///
  /// 返回值：删除条数（items/tasks）。
  Future<(int deletedItems, int deletedTasks)> clearMockData() async {
    if (!kDebugMode) {
      throw StateError('MockDataService 仅允许在 Debug 模式下使用');
    }
    return db.transaction(() async {
      // 先删任务，再删内容：避免未来出现“任务引用非 Mock 内容”的混杂场景。
      final deletedTasks = await _reviewTaskDao.deleteMockReviewTasks();
      final deletedItems = await _learningItemDao.deleteMockLearningItems();
      return (deletedItems, deletedTasks);
    });
  }

  /// 清空全部数据（危险操作，仅 Debug）。
  ///
  /// 说明：
  /// - 仅用于开发调试，避免污染真实用户数据
  /// - 会删除学习内容、复习任务、主题、模板、同步日志等业务数据
  /// - 不删除设置项（避免调试时反复配置）
  Future<void> clearAllData() async {
    if (!kDebugMode) {
      throw StateError('MockDataService 仅允许在 Debug 模式下使用');
    }

    await db.transaction(() async {
      // 注意删除顺序：先删关系表，再删主表。
      await (db.delete(db.topicItemRelations)).go();
      await (db.delete(db.reviewTasks)).go();
      await (db.delete(db.learningItems)).go();
      await (db.delete(db.learningTemplates)).go();
      await (db.delete(db.learningTopics)).go();

      // 同步相关数据一并清理，避免“脏映射/脏游标”影响下一轮测试。
      await (db.delete(db.syncEntityMappings)).go();
      await (db.delete(db.syncLogs)).go();
      await (db.delete(db.syncDevices)).go();
    });
  }

  void _validateConfig(MockDataConfig config) {
    if (config.contentCount < 1 || config.contentCount > 100) {
      throw ArgumentError('学习内容数量需在 1-100 之间');
    }
    if (config.taskCount < 1 || config.taskCount > 500) {
      throw ArgumentError('复习任务数量需在 1-500 之间');
    }
    const allowed = {7, 14, 30, 60, 90};
    if (!allowed.contains(config.daysRange)) {
      throw ArgumentError('复习日期范围仅支持 7/14/30/60/90 天');
    }
  }

  int _pickRoundByWeight() {
    // 权重：1天20%，2天25%，4天25%，7天15%，15天15%。
    final r = _random.nextInt(100);
    if (r < 20) return 1;
    if (r < 45) return 2;
    if (r < 70) return 3;
    if (r < 85) return 4;
    return 5;
  }

  String _pickStatus({required DateTime scheduledAt, required DateTime now}) {
    // 经验分布：
    // - 今天及未来（理论上不会出现未来，但仍做保护）尽量保持 pending
    // - 历史日期：混入 done/skipped，便于测试筛选与统计
    final scheduledDay = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (!scheduledDay.isBefore(today)) return 'pending';

    final r = _random.nextInt(100);
    if (r < 55) return 'pending';
    if (r < 90) return 'done';
    return 'skipped';
  }

  (DateTime? completedAt, DateTime? skippedAt) _statusTimestamps({
    required String status,
    required DateTime scheduledAt,
  }) {
    final base = scheduledAt.add(Duration(minutes: _random.nextInt(8 * 60)));
    switch (status) {
      case 'done':
        return (base, null);
      case 'skipped':
        return (null, base);
      case 'pending':
      default:
        return (null, null);
    }
  }

  DateTime _randomDay({
    required DateTime start,
    required DateTime endInclusive,
  }) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    );
    final days = endDay.difference(startDay).inDays;
    final offset = days <= 0 ? 0 : _random.nextInt(days + 1);
    return startDay.add(Duration(days: offset));
  }

  DateTime _withRandomTime(DateTime day) {
    final h = _random.nextInt(24);
    final m = _random.nextInt(60);
    return DateTime(day.year, day.month, day.day, h, m);
  }

  String _mockTitle({required MockDataConfig config, required int index}) {
    final template = _resolveTemplate(config.template);
    final raw = switch (template) {
      MockDataTemplate.englishWords => _englishWordTitle(index),
      MockDataTemplate.historyEvents => _historyEventTitle(index),
      MockDataTemplate.custom =>
        '${config.customPrefix.trim().isEmpty ? '自定义' : config.customPrefix.trim()} #${index + 1}',
      MockDataTemplate.random => _englishWordTitle(index),
    };
    // ≤50 字：过长时截断（避免触发表约束）。
    return raw.length <= 50 ? raw : raw.substring(0, 50);
  }

  MockDataTemplate _resolveTemplate(MockDataTemplate template) {
    if (template != MockDataTemplate.random) return template;
    final options = const [
      MockDataTemplate.englishWords,
      MockDataTemplate.historyEvents,
      MockDataTemplate.custom,
    ];
    return options[_random.nextInt(options.length)];
  }

  String _englishWordTitle(int index) {
    const words = [
      'abandon',
      'abstract',
      'accelerate',
      'accurate',
      'achieve',
      'adapt',
      'adventure',
      'ancient',
      'analyze',
      'approach',
      'assemble',
      'balance',
      'benefit',
      'brief',
      'capture',
      'clarify',
      'combine',
      'compare',
      'concept',
      'confirm',
      'contrast',
      'crucial',
      'decline',
      'define',
      'derive',
      'detect',
      'efficient',
      'emerge',
      'emphasis',
      'enhance',
      'estimate',
      'evidence',
      'expand',
      'feature',
      'flexible',
      'focus',
      'fundamental',
      'generate',
      'hypothesis',
      'identify',
      'illustrate',
      'impact',
      'improve',
      'indicate',
      'influence',
      'innovate',
      'integrate',
      'interpret',
      'maintain',
      'measure',
      'method',
      'notion',
      'obtain',
      'participate',
      'perceive',
      'persist',
      'potential',
      'priority',
      'process',
      'progress',
      'promote',
      'recover',
      'reflect',
      'relevant',
      'resolve',
      'resource',
      'respond',
      'significant',
      'strategy',
      'structure',
      'sustain',
      'transform',
      'valid',
      'verify',
    ];
    final word = words[index % words.length];
    return '单词：$word';
  }

  String _historyEventTitle(int index) {
    const events = [
      '工业革命的起源',
      '文艺复兴的核心思想',
      '大航海时代的影响',
      '第一次世界大战导火索',
      '第二次世界大战转折点',
      '冷战格局形成原因',
      '丝绸之路的意义',
      '秦统一六国的条件',
      '唐宋变革的主要特征',
      '明清海禁政策的后果',
      '近代科学革命的代表人物',
      '启蒙运动的主要观点',
      '美国独立战争的背景',
      '法国大革命的阶段',
      '苏联解体的原因',
    ];
    final e = events[index % events.length];
    return '历史：$e';
  }

  String _mockNote({required DateTime learningDay, required DateTime now}) {
    final y = learningDay.year;
    final m = learningDay.month.toString().padLeft(2, '0');
    final d = learningDay.day.toString().padLeft(2, '0');
    return 'Mock 数据：用于调试与体验优化验证（生成于 ${now.toIso8601String()}，学习日 $y-$m-$d）。';
  }
}
