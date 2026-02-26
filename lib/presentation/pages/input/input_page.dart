/// 文件用途：录入页（学习内容录入），支持一次录入多条内容并自动生成复习计划。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/learning_topic.dart';
import '../../../domain/entities/review_interval_config.dart';
import '../../../domain/usecases/create_learning_item_usecase.dart';
import '../../../domain/usecases/manage_template_usecase.dart';
import '../../../domain/usecases/manage_topic_usecase.dart';
import '../../providers/home_tasks_provider.dart';
import '../../providers/review_intervals_provider.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/review_preview_panel.dart';
import '../../widgets/speech_input_field.dart';
import 'draft_learning_item.dart';
import 'import_preview_page.dart';
import 'ocr_result_page.dart';
import 'templates_page.dart';

class InputPage extends ConsumerStatefulWidget {
  /// 录入页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const InputPage({super.key});

  @override
  ConsumerState<InputPage> createState() => _InputPageState();
}

class _InputPageState extends ConsumerState<InputPage> {
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  final List<_DraftItemControllers> _items = [];
  int _activeIndex = 0;
  late final Future<List<String>> _availableTagsFuture;
  Map<int, LearningTopicEntity> _topicCache = {};

  @override
  void initState() {
    super.initState();
    // v1.0 MVP：默认提供一条输入项。
    _items.add(_DraftItemControllers());
    _availableTagsFuture = ref
        .read(learningItemRepositoryProvider)
        .getAllTags();
    _warmupTopics();
  }

  Future<void> _warmupTopics() async {
    try {
      final useCase = ref.read(manageTopicUseCaseProvider);
      final topics = await useCase.getAll();
      if (!mounted) return;
      setState(() {
        _topicCache = {for (final t in topics) if (t.id != null) t.id!: t};
      });
    } catch (_) {
      // 主题列表加载失败不影响录入主流程。
    }
  }

  @override
  void dispose() {
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    try {
      final useCase = ref.read(createLearningItemUseCaseProvider);
      final topicUseCase = ref.read(manageTopicUseCaseProvider);
      final intervals = _readIntervals();

      var success = 0;
      var failed = 0;
      final errors = <String>[];

      for (final c in _items) {
        final title = c.title.text.trim();
        final note = c.note.text.trim();
        final tags = _parseTags(c.tags.text);

        final params = CreateLearningItemParams(
          title: title,
          note: note.isEmpty ? null : note,
          tags: tags,
          reviewIntervals: intervals,
        );

        try {
          final result = await useCase.execute(params);
          success++;

          final topicId = c.topicId;
          if (topicId != null) {
            try {
              await topicUseCase.addItemToTopic(topicId, result.item.id!);
            } catch (e) {
              errors.add('「$title」已创建，但关联主题失败：$e');
            }
          }
        } catch (e) {
          failed++;
          errors.add('「$title」保存失败：$e');
        }
      }

      // 刷新首页数据（同时会同步小组件）。
      await ref.read(homeTasksProvider.notifier).load();

      if (!mounted) return;

      if (failed == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存成功：$success 条')),
        );
        Navigator.of(context).pop();
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('保存结果'),
            content: SizedBox(
              width: double.maxFinite,
              height: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('成功：$success 条  失败：$failed 条'),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView.builder(
                      itemCount: errors.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            '• ${errors[index]}',
                            style: AppTypography.bodySecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<ReviewIntervalConfigEntity> _readIntervals() {
    final state = ref.read(reviewIntervalsProvider);
    if (state.configs.isNotEmpty) return state.configs;
    // 兜底：配置尚未加载时，使用默认间隔。
    const defaults = [1, 2, 4, 7, 15];
    return List<ReviewIntervalConfigEntity>.generate(
      defaults.length,
      (index) => ReviewIntervalConfigEntity(
        round: index + 1,
        intervalDays: defaults[index],
        enabled: true,
      ),
    );
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[，,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _addItem() {
    setState(() => _items.add(_DraftItemControllers()));
  }

  void _addDrafts(List<DraftLearningItem> drafts) {
    setState(() {
      for (final d in drafts) {
        final c = _DraftItemControllers();
        c.title.text = d.title;
        c.note.text = d.note ?? '';
        c.tags.text = d.tags.join(', ');
        c.topicId = d.topicId;
        _items.add(c);
      }
      if (drafts.isNotEmpty) _activeIndex = _items.length - 1;
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录入'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _onSave,
            child: _saving ? const Text('保存中...') : const Text('保存'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(240),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                offset: Offset(0, -2),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          final drafts =
                              await Navigator.of(context).push<List<DraftLearningItem>>(
                                MaterialPageRoute(
                                  builder: (_) => const ImportPreviewPage(),
                                  fullscreenDialog: true,
                                ),
                              );
                          if (drafts == null || drafts.isEmpty) return;
                          _addDrafts(drafts);
                        },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('批量导入'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _showTemplateSheet,
                  icon: const Icon(Icons.content_paste),
                  label: const Text('模板'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _startOcrFlow,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('OCR'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('今天学了什么？', style: AppTypography.h2),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          '录入后会按复习间隔自动生成复习任务（可在下方预览调整）。',
                          style: AppTypography.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controllers = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeIndex = index),
                      child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '条目 ${index + 1}',
                                  style: AppTypography.h2,
                                ),
                                if (_activeIndex == index) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  const Text(
                                    '当前',
                                    style: AppTypography.bodySecondary,
                                  ),
                                ],
                                const Spacer(),
                                IconButton(
                                  tooltip: '删除条目',
                                  onPressed: _saving
                                      ? null
                                      : () => _removeItem(index),
                                  icon: const Icon(Icons.delete_outline),
                                  color: _items.length <= 1
                                      ? AppColors.textSecondary
                                      : AppColors.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SpeechInputField(
                              controller: controllers.title,
                              labelText: '标题（必填）',
                              hintText: '例如：Java 集合框架',
                              maxLength: 50,
                              enabled: !_saving,
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return '请输入标题';
                                if (value.length > 50) return '标题最多 50 字';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SpeechInputField(
                              controller: controllers.note,
                              labelText: '备注（选填）',
                              hintText: '补充重点、易错点等',
                              minLines: 2,
                              maxLines: 6,
                              enabled: !_saving,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: controllers.tags,
                              decoration: const InputDecoration(
                                labelText: '标签（选填，用逗号分隔）',
                                hintText: '例如：Java, 面试',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('添加到主题'),
                              subtitle: Text(
                                _topicName(controllers.topicId) ?? '不选择主题',
                                style: AppTypography.bodySecondary,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _saving ? null : () => _pickTopic(index),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FutureBuilder<List<String>>(
                              future: _availableTagsFuture,
                              builder: (context, snapshot) {
                                final tags = snapshot.data ?? const <String>[];
                                if (tags.isEmpty) {
                                  return const Text(
                                    '还没有标签，创建一个吧',
                                    style: AppTypography.bodySecondary,
                                  );
                                }
                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: tags.take(12).map((t) {
                                    return ActionChip(
                                      label: Text(t),
                                      onPressed: _saving
                                          ? null
                                          : () =>
                                                _appendTag(controllers.tags, t),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('再添加一条'),
                ),
                const SizedBox(height: AppSpacing.lg),
                ReviewPreviewPanel(
                  learningDate: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: ColoredBox(
                // v1.0 MVP：避免使用 withOpacity 的精度警告，改为 withAlpha。
                color: Colors.black.withAlpha((0.15 * 255).round()),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  void _appendTag(TextEditingController controller, String tag) {
    final current = _parseTags(controller.text);
    if (current.contains(tag)) return;
    current.add(tag);
    controller.text = current.join(', ');
  }

  String? _topicName(int? topicId) {
    if (topicId == null) return null;
    return _topicCache[topicId]?.name ?? '主题 #$topicId';
  }

  Future<void> _pickTopic(int index) async {
    final useCase = ref.read(manageTopicUseCaseProvider);
    List<LearningTopicEntity> topics = const [];
    try {
      topics = await useCase.getAll();
      if (!mounted) return;
      setState(() {
        _topicCache = {for (final t in topics) if (t.id != null) t.id!: t};
      });
    } catch (_) {}

    final currentId = _items[index].topicId;
    final picked = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('新建主题'),
                onTap: () async {
                  final nameController = TextEditingController();
                  final descController = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('新建主题'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: '主题名称（必填）',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: descController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: '主题描述（选填）',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('创建'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  if (name.isEmpty) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('主题名称不能为空')),
                    );
                    return;
                  }

                  try {
                    final created = await useCase.create(
                      TopicParams(
                        name: name,
                        description: desc.isEmpty ? null : desc,
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(created.id);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('创建失败：$e')),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('不选择主题'),
                trailing: currentId == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(null),
              ),
              const Divider(height: 1),
              if (topics.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '暂无主题，可先在设置页创建主题',
                    style: AppTypography.bodySecondary,
                  ),
                )
              else
                ...topics.map((t) {
                  return ListTile(
                    title: Text(t.name),
                    subtitle: (t.description ?? '').trim().isEmpty
                        ? null
                        : Text(
                            t.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: currentId == t.id ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(context).pop(t.id),
                  );
                }),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _items[index].topicId = picked);
  }

  Future<void> _showTemplateSheet() async {
    // 确保模板列表已加载。
    final templatesState = ref.read(templatesProvider);
    if (templatesState.isLoading) {
      // ignore: unused_result
      ref.read(templatesProvider.notifier).load();
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(templatesProvider);
            final useCase = ref.read(manageTemplateUseCaseProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('选择模板', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.md),
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state.templates.isEmpty)
                      const Text(
                        '还没有模板，点击下方“管理模板”创建',
                        style: AppTypography.bodySecondary,
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 1.6,
                              ),
                          itemCount: state.templates.length,
                          itemBuilder: (context, i) {
                            final t = state.templates[i];
                            return InkWell(
                              onTap: () {
                                final applied = useCase.applyTemplate(t);
                                final idx = _activeIndex.clamp(0, _items.length - 1);
                                final c = _items[idx];
                                c.title.text = applied['title'] ?? '';
                                c.note.text = applied['note'] ?? '';
                                c.tags.text = t.tags.join(', ');
                                Navigator.of(context).pop();
                              },
                              child: GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: AppTypography.h2.copyWith(fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        t.titlePattern,
                                        style: AppTypography.bodySecondary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await Navigator.of(this.context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TemplatesPage(),
                                  fullscreenDialog: true,
                                ),
                              );
                              if (!mounted) return;
                              // 返回后刷新模板列表，确保及时更新。
                              ref.read(templatesProvider.notifier).load();
                            },
                            child: const Text('管理模板'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _saveActiveAsTemplate();
                            },
                            child: const Text('保存为模板'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveActiveAsTemplate() async {
    final idx = _activeIndex.clamp(0, _items.length - 1);
    final c = _items[idx];
    final title = c.title.text.trim();
    final note = c.note.text.trim();
    final tags = _parseTags(c.tags.text);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前条目标题为空，无法保存为模板')),
      );
      return;
    }

    final nameController = TextEditingController(text: title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存为模板'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '模板名称（必填）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模板名称不能为空')),
      );
      return;
    }

    final params = TemplateParams(
      name: name,
      titlePattern: title,
      notePattern: note.isEmpty ? null : note,
      tags: tags,
      sortOrder: 0,
    );

    final notifier = ref.read(templatesProvider.notifier);
    try {
      await notifier.create(params);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模板已保存')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (!msg.contains('模板名称已存在')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存模板失败：$e')),
        );
        return;
      }

      final overwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('模板名称已存在'),
          content: const Text('是否覆盖同名模板？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('覆盖'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (overwrite != true) return;

      final list = ref.read(templatesProvider).templates;
      final target = list.firstWhere((t) => t.name.trim() == name);
      try {
        await notifier.update(target, params);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已覆盖保存')),
        );
      } catch (e2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('覆盖失败：$e2')),
        );
      }
    }
  }

  Future<void> _startOcrFlow() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<_OcrSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照识别'),
                onTap: () => Navigator.of(context).pop(_OcrSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择（可多选）'),
                onTap: () => Navigator.of(context).pop(_OcrSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      List<String> paths = [];
      if (source == _OcrSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          final go = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('需要相机权限'),
              content: const Text('拍照识别需要相机权限。你可以前往系统设置开启权限，或改用相册选择。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('去设置'),
                ),
              ],
            ),
          );
          if (go == true) {
            await openAppSettings();
          }
          return;
        }
        final file = await picker.pickImage(source: ImageSource.camera);
        if (file == null) return;
        paths = [file.path];
      } else {
        final files = await picker.pickMultiImage();
        if (files.isEmpty) return;
        paths = files.map((e) => e.path).toList();
      }

      if (!mounted) return;
      final drafts =
          await Navigator.of(context).push<List<DraftLearningItem>>(
            MaterialPageRoute(
              builder: (_) => OcrResultPage(imagePaths: paths),
              fullscreenDialog: true,
            ),
          );
      if (drafts == null || drafts.isEmpty) return;
      _addDrafts(drafts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR 识别失败：$e')),
      );
    }
  }
}

enum _OcrSource { camera, gallery }

class _DraftItemControllers {
  _DraftItemControllers()
    : title = TextEditingController(),
      note = TextEditingController(),
      tags = TextEditingController();

  final TextEditingController title;
  final TextEditingController note;
  final TextEditingController tags;
  int? topicId;

  /// 释放控制器资源。
  void dispose() {
    title.dispose();
    note.dispose();
    tags.dispose();
  }
}
