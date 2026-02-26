/// 文件用途：语音输入组件（SpeechInputField），在文本输入框右侧提供麦克风按钮并集成语音识别（F1.3）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../di/providers.dart';

class SpeechInputField extends ConsumerStatefulWidget {
  /// 带语音按钮的输入框。
  const SpeechInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool enabled;

  @override
  ConsumerState<SpeechInputField> createState() => _SpeechInputFieldState();
}

class _SpeechInputFieldState extends ConsumerState<SpeechInputField> {
  bool _speechSupported = true;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final service = ref.read(speechServiceProvider);
    try {
      final ok = await service.initialize();
      if (!mounted) return;
      setState(() {
        _speechSupported = ok;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechSupported = false;
        _initializing = false;
      });
    }
  }

  Future<void> _startSpeech() async {
    final service = ref.read(speechServiceProvider);

    if (!_speechSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设备不支持语音识别')),
      );
      return;
    }

    // v2.1：语音识别以“替换当前输入”为默认策略，避免在标题/备注中产生重复片段。
    final original = widget.controller.text;
    widget.controller.text = '';

    var latest = '';
    StateSetter? dialogSetState;
    var dialogOpen = true;

    Future<void> closeDialog() async {
      if (!dialogOpen) return;
      dialogOpen = false;
      if (mounted) Navigator.of(context).pop();
    }

    Future<void> stop({required bool restoreOnCancel}) async {
      try {
        await service.stop();
      } catch (_) {}
      if (restoreOnCancel && latest.trim().isEmpty) {
        widget.controller.text = original;
      }
      await closeDialog();
    }

    // 先弹出 UI，再异步启动识别，避免启动耗时导致按钮无响应。
    // ignore: unawaited_futures
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            dialogSetState = setLocal;
            return AlertDialog(
              title: const Text('🎤 录音中...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Wave(),
                  const SizedBox(height: AppSpacing.md),
                  const Text('请开始说话', style: AppTypography.bodySecondary),
                  if (latest.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(latest, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => stop(restoreOnCancel: true),
                  child: const Text('停止'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      await service.startListening(
        onResult: (text) {
          latest = text;
          widget.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          dialogSetState?.call(() {});
        },
      );
    } catch (e) {
      widget.controller.text = original;
      await closeDialog();
      if (!mounted) return;

      final message = e.toString();
      if (message.contains('麦克风权限')) {
        final go = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要麦克风权限'),
            content: const Text('语音识别需要麦克风权限。你可以前往系统设置开启权限，或继续手动输入。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('手动输入'),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('语音识别失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUseSpeech =
        widget.enabled && !_initializing && _speechSupported;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        suffixIcon: IconButton(
          tooltip: '语音输入',
          onPressed: canUseSpeech ? _startSpeech : null,
          icon: const Icon(Icons.mic),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class _Wave extends StatefulWidget {
  const _Wave();

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 关键逻辑：用简单柱状波形模拟声波动画，避免引入额外依赖。
        final heights = [
          8 + 10 * t,
          16 + 14 * (1 - t),
          24 + 18 * t,
          16 + 14 * (1 - t),
          8 + 10 * t,
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: heights.map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
