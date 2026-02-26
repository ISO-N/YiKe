/// 文件用途：配对服务（F12）——生成/校验 6 位配对码，并定义有效期规则。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:math';

/// 配对服务。
class PairingService {
  PairingService._();

  /// 配对码有效期（5 分钟）。
  static const Duration pairingCodeValidity = Duration(minutes: 5);

  /// 生成 6 位数字配对码（如 123456）。
  static String generatePairingCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// 校验配对码。
  static bool verifyPairingCode(String input, String expected) {
    return input.trim() == expected.trim();
  }
}
