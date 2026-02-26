// 文件用途：OcrRecognitionUseCase 单元测试（调用透传）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter_test/flutter_test.dart';
import 'package:yike/domain/services/ocr_service.dart';
import 'package:yike/domain/usecases/ocr_recognition_usecase.dart';

void main() {
  test('execute 会调用 OcrService.recognizeText 并返回结果', () async {
    final service = _FakeOcrService();
    final usecase = OcrRecognitionUseCase(ocrService: service);

    final out = await usecase.execute('path/to/image.png');
    expect(service.lastPath, 'path/to/image.png');
    expect(out.text, 'hello');
    expect(out.confidence, 0.9);
  });
}

class _FakeOcrService implements OcrService {
  String? lastPath;

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    lastPath = imagePath;
    return const OcrResult(text: 'hello', confidence: 0.9);
  }
}

