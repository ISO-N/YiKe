/// 文件用途：用例 - OCR 识别（OcrRecognitionUseCase），用于图片文字识别（F1.4）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import '../services/ocr_service.dart';

/// OCR 识别用例。
class OcrRecognitionUseCase {
  /// 构造函数。
  const OcrRecognitionUseCase({required OcrService ocrService})
    : _ocrService = ocrService;

  final OcrService _ocrService;

  /// 执行 OCR 识别。
  Future<OcrResult> execute(String imagePath) {
    return _ocrService.recognizeText(imagePath);
  }
}
