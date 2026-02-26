/// 文件用途：主题详情页（TopicDetailPage），展示主题进度与关联内容列表并支持管理关联（F1.6）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/learning_item.dart';
import '../../../domain/entities/learning_topic.dart';
import '../../../domain/entities/review_task.dart';
import '../../widgets/glass_card.dart';
import '../../providers/topics_provider.dart';

class TopicDetailPage extends ConsumerStatefulWidget {
  /// 主题详情页。
  const TopicDetailPage({super.key, required this.topicId});

  final int topicId;

  @override
  ConsumerState<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends ConsumerState<TopicDetailPage> {
  bool _loading = true;
  String? _error;
  LearningTopicEntity? _topic;
  List<_TopicItemView> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final useCase = ref.read(manageTopicUseCaseProvider);
      final topic = await useCase.getById(widget.topicId);
      if (topic == null) {
        setState(() {
          _loading = false;
          _error = '主题不存在';
        });
        return;
      }

      final itemRepo = ref.read(learningItemRepositoryProvider);
      final taskRepo = ref.read(reviewTaskRepositoryProvider);

      final allItems = await itemRepo.getAll();
      final allTasks = await taskRepo.getAllTasks();

      final itemIds = topic.itemIds.toSet();
      final items = allItems.where((e) => e.id != null && itemIds.contains(e.id)).toList();

      final taskMap = <int, List<ReviewTaskEntity>>{};
      for (final t in allTasks) {
        taskMap.putIfAbsent(t.learningItemId, () => []).add(t);
      }

      final views = items.map((it) {
        final tasks = (taskMap[it.id!] ?? const <ReviewTaskEntity>[]);
        final total = tasks.where((e) => e.status != ReviewTaskStatus.skipped).length;
        final done = tasks.where((e) => e.status == ReviewTaskStatus.done).length;
        final pendingRounds = tasks
            .where((e) => e.status == ReviewTaskStatus.pending)
            .map((e) => e.reviewRound)
            .toList()
          ..sort();
        final nextRound = pendingRounds.isEmpty ? null : pendingRounds.first;
        return _TopicItemView(
          item: it,
          total: total,
          done: done,
          nextRound: nextRound,
        );
      }).toList()
        ..sort((a, b) => a.item.createdAt.compareTo(b.item.createdAt));

      setState(() {
        _topic = topic;
        _items = views;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addRelations() async {
    final topic = _topic;
    if (topic == null) return;

    final itemRepo = ref.read(learningItemRepositoryProvider);
    final allItems = await itemRepo.getAll();
    if (!mounted) return;
    final existing = topic.itemIds.toSet();
    final candidates = allItems.where((e) => e.id != null && !existing.contains(e.id)).toList();

    final selected = <int>{};
    final searchController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final keyword = searchController.text.trim();
            final filtered = keyword.isEmpty
                ? candidates
                : candidates.where((e) => e.title.contains(keyword)).toList();
            return AlertDialog(
              title: const Text('添加关联内容'),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索标题',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final it = filtered[index];
                          final id = it.id!;
                          final checked = selected.contains(id);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) => setLocal(() {
                              if (v == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            }),
                            title: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty ? null : () => Navigator.of(context).pop(true),
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;

    if (ok != true || selected.isEmpty) return;

    try {
      final useCase = ref.read(manageTopicUseCaseProvider);
      for (final id in selected) {
        await useCase.addItemToTopic(topic.id!, id);
      }
      // 刷新列表页状态与当前详情。
      ref.read(topicsProvider.notifier).load();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加失败：$e')),
      );
    }
  }

  Future<void> _removeRelation(int learningItemId) async {
    final topic = _topic;
    if (topic == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除关联'),
        content: const Text('确定从该主题中移除此内容吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    try {
      final useCase = ref.read(manageTopicUseCaseProvider);
      await useCase.removeItemFromTopic(topic.id!, learningItemId);
      ref.read(topicsProvider.notifier).load();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('移除失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    final overviews = ref.watch(topicsProvider).overviews;
    final overview =
        overviews.where((e) => e.topic.id == widget.topicId).toList().firstOrNull;

    final completed = overview?.completedCount ?? 0;
    final total = overview?.totalCount ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(topic?.name ?? '主题详情'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null)
                  ? GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          '加载失败：$_error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topic!.name,
                                  style: AppTypography.h2(context),
                                ),
                                if ((topic.description ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    topic.description!,
                                    style: AppTypography.bodySecondary(context),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${topic.itemIds.length} 条内容   $completed/$total 完成',
                                  style: AppTypography.bodySecondary(context),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkGlassBorder
                                            : AppColors.glassBorder,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '关联内容',
                                style: AppTypography.h2(context),
                              ),
                            ),
                            FilledButton(
                              onPressed: _addRelations,
                              child: const Text('+ 添加关联内容'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: _items.isEmpty
                              ? Center(
                                  child: Text(
                                    '暂无内容，点击上方按钮添加',
                                    style: AppTypography.bodySecondary(context),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _items.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final v = _items[index];
                                    final done = v.done;
                                    final total = v.total;
                                    final checked = total > 0 && done >= total;
                                    final subtitle = v.nextRound == null
                                        ? '已完成'
                                        : '待复习：第${v.nextRound}次';
                                    return Dismissible(
                                      key: ValueKey(v.item.id),
                                      direction: DismissDirection.endToStart,
                                      background: const SizedBox.shrink(),
                                      secondaryBackground: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withAlpha(30),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      confirmDismiss: (_) async {
                                        await _removeRelation(v.item.id!);
                                        return false;
                                      },
                                      child: GlassCard(
                                        child: CheckboxListTile(
                                          value: checked,
                                          onChanged: null,
                                          title: Text(v.item.title),
                                          subtitle: Text(
                                            '$subtitle  （$done/$total）',
                                            style: AppTypography.bodySecondary(context),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _TopicItemView {
  const _TopicItemView({
    required this.item,
    required this.total,
    required this.done,
    required this.nextRound,
  });

  final LearningItemEntity item;
  final int total;
  final int done;
  final int? nextRound;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
