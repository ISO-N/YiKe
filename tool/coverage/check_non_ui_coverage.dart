/// 文件用途：非 UI 代码覆盖率校验脚本（读取 `coverage/lcov.info`，按目录白名单统计行覆盖率）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'dart:io';

/// 非 UI 覆盖率统计配置。
///
/// 说明：
/// - 采用“目录白名单 + 文件黑名单”的口径，避免 UI（presentation）与生成代码（*.g.dart）拉低覆盖率。
/// - 覆盖率数据源为 `flutter test --coverage` 生成的 `coverage/lcov.info`。
class NonUiCoverageConfig {
  /// 非 UI 代码目录白名单（相对仓库根目录）。
  static const List<String> includeDirPrefixes = <String>[
    'lib/core/utils/',
    'lib/domain/',
    'lib/data/',
    'lib/infrastructure/storage/',
  ];

  /// 文件黑名单（相对路径包含以下任意片段则排除）。
  static const List<String> excludePathContains = <String>[
    '/presentation/',
    '.g.dart',
    'lib/app.dart',
    'lib/main.dart',
    // Drift 的表定义文件主要用于代码生成，运行时无法直接实例化/覆盖，避免纳入口径导致覆盖率失真。
    'lib/data/database/tables/',
  ];

  /// 覆盖率阈值（百分比）。
  static const double minLineCoveragePercent = 90.0;
}

/// LCOV 单个源文件的汇总结果。
class LcovSummary {
  const LcovSummary({
    required this.linesFound,
    required this.linesHit,
  });

  final int linesFound;
  final int linesHit;
}

Future<void> main(List<String> args) async {
  // 读取仓库根目录（默认当前目录）。
  final repoRoot = Directory.current;

  // 读取 lcov 文件路径。
  final lcovPath = args.isNotEmpty ? args.first : 'coverage/lcov.info';
  final lcovFile = File(lcovPath);
  if (!await lcovFile.exists()) {
    stderr.writeln('未找到覆盖率文件：$lcovPath');
    stderr.writeln('请先执行：flutter test --coverage');
    exitCode = 2;
    return;
  }

  // 1) 枚举非 UI 代码范围内的所有 Dart 源文件。
  final scopeFiles = await _collectScopeFiles(repoRoot);
  if (scopeFiles.isEmpty) {
    stderr.writeln('未找到任何纳入统计的 Dart 文件，请检查 NonUiCoverageConfig.includeDirPrefixes。');
    exitCode = 2;
    return;
  }

  // 2) 解析 lcov 汇总数据（按文件聚合 LF/LH）。
  final lcovSummaries = await _parseLcovSummaries(lcovFile, repoRoot);

  // 3) 校验是否所有 scope 文件都出现在 lcov 中（避免“未加载文件不计入覆盖率”的虚高）。
  final missingAll = scopeFiles.where((p) => !lcovSummaries.containsKey(p)).toList()..sort();
  final missingCoverable = <String>[];
  for (final p in missingAll) {
    // 说明：部分“纯接口/纯声明”文件在 VM 覆盖率中可能不会生成 record（没有可插桩行）。
    // 这类文件不应当作为“未加载导致覆盖率虚高”的判定依据，因此这里做一次轻量启发式识别。
    if (await _isPotentiallyCoverable(repoRoot, p)) {
      missingCoverable.add(p);
    }
  }
  if (missingCoverable.isNotEmpty) {
    stderr.writeln('以下文件未出现在 lcov 中（通常意味着未被任何测试 import/加载）：');
    for (final p in missingCoverable) {
      stderr.writeln('- $p');
    }
    stderr.writeln('建议：在 `test/coverage/non_ui_imports_test.dart` 中补充 import，或为这些文件添加单测。');
    exitCode = 2;
    return;
  }

  // 4) 统计总行覆盖率（按 scopeFiles 汇总）。
  var totalFound = 0;
  var totalHit = 0;
  for (final p in scopeFiles) {
    final s = lcovSummaries[p];
    if (s == null) continue;
    totalFound += s.linesFound;
    totalHit += s.linesHit;
  }

  if (totalFound <= 0) {
    stderr.writeln('覆盖率统计失败：LF=0（未找到可统计的行）。');
    exitCode = 2;
    return;
  }

  final percent = totalHit * 100.0 / totalFound;
  final percentStr = percent.toStringAsFixed(2);
  stdout.writeln('非 UI 行覆盖率：$percentStr%（$totalHit/$totalFound）');

  if (percent + 1e-9 < NonUiCoverageConfig.minLineCoveragePercent) {
    stderr.writeln(
      '未达到阈值：${NonUiCoverageConfig.minLineCoveragePercent.toStringAsFixed(2)}%（当前 $percentStr%）',
    );
    exitCode = 1;
  }
}

Future<List<String>> _collectScopeFiles(Directory repoRoot) async {
  final scopeFiles = <String>[];
  for (final dirPrefix in NonUiCoverageConfig.includeDirPrefixes) {
    final dir = Directory('${repoRoot.path}${Platform.pathSeparator}${dirPrefix.replaceAll('/', Platform.pathSeparator)}');
    if (!await dir.exists()) continue;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final relative = _normalizePath(_relativePath(repoRoot.path, entity.path));
      if (_isExcluded(relative)) continue;
      scopeFiles.add(relative);
    }
  }
  scopeFiles.sort();
  return scopeFiles;
}

bool _isExcluded(String normalizedRelativePath) {
  for (final pattern in NonUiCoverageConfig.excludePathContains) {
    if (normalizedRelativePath.contains(pattern)) return true;
  }
  return false;
}

Future<Map<String, LcovSummary>> _parseLcovSummaries(File lcovFile, Directory repoRoot) async {
  final map = <String, LcovSummary>{};

  String? currentFile;
  int? currentLf;
  int? currentLh;

  // 说明：LCOV 中每条 record 以 end_of_record 结束；我们只关心 SF/LF/LH。
  final lines = await lcovFile.readAsLines();
  for (final raw in lines) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      // 注意：lcov 里可能是 Windows 反斜杠路径。
      final sf = _normalizePath(line.substring(3));
      // 兼容 SF 为绝对路径的情况：统一转换为仓库根目录下的相对路径，确保与 scopeFiles 的 key 一致。
      currentFile = _normalizePath(_relativePath(repoRoot.path, sf));
      currentLf = null;
      currentLh = null;
      continue;
    }

    if (line.startsWith('LF:')) {
      currentLf = int.tryParse(line.substring(3));
      continue;
    }

    if (line.startsWith('LH:')) {
      currentLh = int.tryParse(line.substring(3));
      continue;
    }

    if (line == 'end_of_record' && currentFile != null) {
      final file = currentFile;
      final lf = currentLf ?? 0;
      final lh = currentLh ?? 0;

      // 只聚合纳入统计范围的文件；其余文件（如 generated/UI）可以存在于 lcov 但不参与计算。
      if (_isInScope(file) && !_isExcluded(file)) {
        final prev = map[file];
        if (prev == null) {
          map[file] = LcovSummary(linesFound: lf, linesHit: lh);
        } else {
          map[file] = LcovSummary(
            linesFound: prev.linesFound + lf,
            linesHit: prev.linesHit + lh,
          );
        }
      }

      currentFile = null;
      currentLf = null;
      currentLh = null;
    }
  }

  return map;
}

bool _isInScope(String normalizedRelativePath) {
  for (final prefix in NonUiCoverageConfig.includeDirPrefixes) {
    if (normalizedRelativePath.startsWith(prefix)) return true;
  }
  return false;
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

String _relativePath(String base, String full) {
  final b = _normalizePath(base).replaceAll(RegExp(r'/*$'), '');
  final f = _normalizePath(full);
  if (f == b) return '.';
  if (f.startsWith('$b/')) return f.substring(b.length + 1);
  return f;
}

Future<bool> _isPotentiallyCoverable(Directory repoRoot, String normalizedRelativePath) async {
  // 说明：该启发式用于识别“可能存在可插桩代码”的文件，避免纯接口/纯声明文件导致误报。
  final file = File(
    '${repoRoot.path}${Platform.pathSeparator}${normalizedRelativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  if (!await file.exists()) return false;

  final content = await file.readAsString();
  // 箭头函数 / getter / 表达式体通常会产生可覆盖行。
  if (content.contains('=>')) return true;

  // 形如：foo(...) { ... } / foo(...) async { ... } 的函数体。
  // Dart 的原始字符串正则：`\)\s*(async\s*)?\{`，匹配形如 `foo(...) {` 或 `foo(...) async {`。
  final hasBlockBody = RegExp(r'\)\s*(async\s*)?\{');
  if (hasBlockBody.hasMatch(content)) return true;
  return false;
}
