/// 文件用途：基础设施 - OCR 服务实现（MlKitOcrService），基于 Google ML Kit（F1.4）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/services/ocr_service.dart';

/// 基于 ML Kit 的 OCR 服务实现。
class MlKitOcrService implements OcrService {
  /// 构造函数。
  ///
  /// 异常：无。
  const MlKitOcrService();

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    // 说明：v2.1 主要面向中英文学习内容；这里选择中文模型以兼顾中文识别效果。
    final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);

      // 关键逻辑：尽可能从可用字段估算置信度；若插件不支持则回退为 1.0。
      final confidence = _estimateConfidence(recognized);
      return OcrResult(text: recognized.text, confidence: confidence);
    } finally {
      await recognizer.close();
    }
  }

  double _estimateConfidence(RecognizedText recognized) {
    final values = <double>[];

    // google_mlkit_text_recognition 的置信度字段在不同平台/版本可能不一致，这里使用动态访问做降级处理。
    for (final block in recognized.blocks) {
      final blockConfidence = _readConfidence(block);
      if (blockConfidence != null) values.add(blockConfidence);
      for (final line in block.lines) {
        final lineConfidence = _readConfidence(line);
        if (lineConfidence != null) values.add(lineConfidence);
        for (final element in line.elements) {
          final elementConfidence = _readConfidence(element);
          if (elementConfidence != null) values.add(elementConfidence);
        }
      }
    }

    if (values.isEmpty) return 1.0;
    final avg = values.reduce((a, b) => a + b) / values.length;
    return avg.isNaN ? 1.0 : math.min(1.0, math.max(0.0, avg));
  }

  double? _readConfidence(Object obj) {
    try {
      final dynamic d = obj;
      final v = d.confidence;
      if (v is num) return v.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }
}
