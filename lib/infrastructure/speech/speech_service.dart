/// 文件用途：基础设施 - 语音识别服务封装（SpeechService），基于 speech_to_text（F1.3）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// 语音识别状态。
enum SpeechServiceStatus { idle, listening, processing }

/// 语音识别服务封装。
///
/// 说明：
/// - 负责权限检查、初始化与开始/停止识别
/// - UI 通过回调获取识别结果与状态变化
class SpeechService {
  SpeechService() : _speech = SpeechToText();

  final SpeechToText _speech;

  bool get isAvailable => _speech.isAvailable;
  bool get isListening => _speech.isListening;

  /// 初始化语音识别引擎。
  ///
  /// 返回值：是否可用。
  Future<bool> initialize() async {
    // 关键逻辑：speech_to_text 自身也会做可用性检测，这里统一入口。
    return _speech.initialize();
  }

  /// 请求麦克风权限（若已授权则直接返回 true）。
  Future<bool> ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final next = await Permission.microphone.request();
    return next.isGranted;
  }

  /// 开始语音识别。
  ///
  /// 参数：
  /// - [onResult] 识别结果回调（包含累积文本）
  /// - [localeId] 语言（可选，空则使用系统默认）
  /// - [partialResults] 是否回传中间结果（默认 true）
  /// 异常：
  /// - 未授权麦克风权限时抛出 [StateError]
  Future<void> startListening({
    required void Function(String text) onResult,
    String? localeId,
    bool partialResults = true,
  }) async {
    final ok = await ensureMicPermission();
    if (!ok) {
      throw StateError('语音识别需要麦克风权限');
    }

    if (!_speech.isAvailable) {
      final available = await initialize();
      if (!available) {
        throw StateError('设备不支持语音识别');
      }
    }

    await _speech.listen(
      localeId: localeId,
      // ignore: deprecated_member_use
      partialResults: partialResults,
      // ignore: deprecated_member_use
      listenMode: ListenMode.confirmation,
      onResult: (result) => onResult(result.recognizedWords),
    );
  }

  /// 停止语音识别。
  Future<void> stop() => _speech.stop();

  /// 取消语音识别（不返回结果）。
  Future<void> cancel() => _speech.cancel();

  /// 获取可用语言列表。
  Future<List<LocaleName>> getLocales() => _speech.locales();
}
