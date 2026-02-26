/// 文件用途：领域服务接口 - OCR 文字识别（OcrService），用于 OCR 识别（F1.4）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

/// OCR 识别结果。
class OcrResult {
  /// 构造函数。
  const OcrResult({required this.text, required this.confidence});

  /// 识别到的文本（原样）。
  final String text;

  /// 置信度（0-1）。
  ///
  /// 说明：不同平台/模型对置信度支持程度不同，业务侧仅做参考展示。
  final double confidence;
}

/// OCR 服务接口。
abstract class OcrService {
  /// 对图片进行 OCR 文字识别。
  ///
  /// 参数：
  /// - [imagePath] 图片本地路径
  /// 返回值：识别结果
  /// 异常：识别失败时可能抛出异常。
  Future<OcrResult> recognizeText(String imagePath);
}
