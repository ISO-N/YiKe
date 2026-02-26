/// 文件用途：将 docs/prd/忆刻学习指南.md 同步到 assets/markdown/learning_guide.md（单一事实源）。
/// 作者：Codex
/// 创建日期：2026-02-26
library;

import 'dart:convert';
import 'dart:io';

/// 学习指南同步入口。
///
/// 说明：
/// - 源文件：docs/prd/忆刻学习指南.md（唯一事实源）
/// - 目标文件：assets/markdown/learning_guide.md（运行时加载的资源文件）
/// - 目标文件会被覆盖，请勿手工编辑
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current.path;
  final source = File('$repoRoot/docs/prd/忆刻学习指南.md');
  final targetDir = Directory('$repoRoot/assets/markdown');
  final target = File('${targetDir.path}/learning_guide.md');

  if (!await source.exists()) {
    stderr.writeln('未找到源文件：${source.path}');
    exitCode = 2;
    return;
  }

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final sourceContent = await source.readAsString(encoding: utf8);
  final header = '<!-- 该文件由 tool/sync_learning_guide.dart 自动生成，请勿手工编辑。 -->\n\n';
  await target.writeAsString(header + sourceContent, encoding: utf8);

  stdout.writeln('已同步学习指南：');
  stdout.writeln('- 源：${source.path}');
  stdout.writeln('- 目标：${target.path}');
}
