/// 文件用途：一键构建 YiKe（忆刻）Windows Release，并使用 Inno Setup 生成安装包
/// 作者：Codex（OpenAI）
/// 创建日期：2026-03-01
///
/// 使用方式（在项目根目录执行）：
///   dart run tool/build_windows_installer.dart
///
/// 可选参数：
///   --skip-flutter-build        跳过 `flutter build windows --release`
///   `--inno-script=<path>`      指定 .iss 脚本路径（默认：tool/installer/windows/yike.iss）
///   `--iscc=<path>`             指定 ISCC.exe 路径（默认：自动从 PATH/常见目录查找）
///
/// 说明：
/// - 本仓库要求 UTF-8（无 BOM），因此优先使用 Dart 脚本承载中文输出，避免 Windows PowerShell 5.1 的编码兼容坑。
library;

import 'dart:io';

/// 函数用途：将多个路径片段拼接为平台正确的路径。
String joinPathAll(Iterable<String> parts) {
  final sep = Platform.pathSeparator;
  final normalized = <String>[];

  for (final raw in parts) {
    var part = raw;
    if (part.isEmpty) continue;
    if (part.endsWith(sep)) part = part.substring(0, part.length - 1);
    if (normalized.isNotEmpty && part.startsWith(sep)) {
      part = part.substring(1);
    }
    normalized.add(part);
  }

  if (normalized.isEmpty) return '';
  var result = normalized.first;
  for (final part in normalized.skip(1)) {
    result = '$result$sep$part';
  }
  return result;
}

/// 函数用途：向上查找包含 pubspec.yaml 的目录，作为项目根目录。
Directory findProjectRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    final pubspec = File(joinPathAll([dir.path, 'pubspec.yaml']));
    if (pubspec.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('未找到 pubspec.yaml，请在项目目录内执行该脚本。');
    }
    dir = parent;
  }
}

/// 函数用途：解析 `--key=value` 与 `--flag` 形式参数。
Map<String, String?> parseArgs(List<String> args) {
  final map = <String, String?>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final eq = arg.indexOf('=');
    if (eq < 0) {
      map[arg.substring(2)] = null;
    } else {
      final key = arg.substring(2, eq);
      final value = arg.substring(eq + 1);
      map[key] = value;
    }
  }
  return map;
}

/// 函数用途：运行外部命令并实时转发 stdout/stderr，返回退出码。
Future<int> runCommand(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

/// 函数用途：尝试定位 ISCC.exe（优先 PATH，其次常见安装目录）。
Future<String> findIsccPath() async {
  // 1) 通过 PATH（where ISCC）
  if (Platform.isWindows) {
    final whereResult = await Process.run('where', const [
      'ISCC',
    ], runInShell: true);
    if (whereResult.exitCode == 0) {
      final out = (whereResult.stdout ?? '').toString().trim();
      if (out.isNotEmpty) {
        final firstLine = out.split(RegExp(r'[\r\n]+')).first.trim();
        if (firstLine.isNotEmpty && File(firstLine).existsSync()) {
          return firstLine;
        }
      }
    }
  }

  // 2) 常见安装目录
  final candidates = <String>[];
  final pf = Platform.environment['ProgramFiles'];
  final pfx86 = Platform.environment['ProgramFiles(x86)'];
  if (pfx86 != null && pfx86.isNotEmpty) {
    candidates.add(joinPathAll([pfx86, 'Inno Setup 6', 'ISCC.exe']));
  }
  if (pf != null && pf.isNotEmpty) {
    candidates.add(joinPathAll([pf, 'Inno Setup 6', 'ISCC.exe']));
  }

  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  throw StateError('未找到 ISCC.exe。请安装 Inno Setup 6，并将 ISCC 加入 PATH。');
}

/// 函数用途：从输出目录中找到最新生成的安装包（.exe）。
File? findLatestInstallerExe(Directory outputDir) {
  if (!outputDir.existsSync()) return null;
  final exeFiles =
      outputDir
          .listSync(recursive: false)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.exe'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return exeFiles.isEmpty ? null : exeFiles.first;
}

Future<void> main(List<String> args) async {
  final flags = parseArgs(args);
  final skipFlutterBuild = flags.containsKey('skip-flutter-build');

  final projectRoot = findProjectRoot();
  final innoScriptPath =
      flags['inno-script'] ??
      joinPathAll([
        projectRoot.path,
        'tool',
        'installer',
        'windows',
        'yike.iss',
      ]);
  final isccPath = flags['iscc'] ?? await findIsccPath();

  final outputDir = Directory(
    joinPathAll([projectRoot.path, 'build', 'installer', 'windows']),
  );
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  stdout.writeln('项目根目录：${projectRoot.path}');
  stdout.writeln('Inno 脚本：$innoScriptPath');
  stdout.writeln('ISCC 路径：$isccPath');

  if (!File(innoScriptPath).existsSync()) {
    stderr.writeln('未找到 Inno 脚本：$innoScriptPath');
    exitCode = 2;
    return;
  }

  if (!skipFlutterBuild) {
    stdout.writeln('开始构建 Windows Release：flutter build windows --release');
    final buildExit = await runCommand('flutter', const [
      'build',
      'windows',
      '--release',
    ], workingDirectory: projectRoot.path);
    if (buildExit != 0) {
      stderr.writeln('flutter build 失败，退出码：$buildExit');
      exitCode = buildExit;
      return;
    }
  } else {
    stdout.writeln('已跳过 flutter build（skip-flutter-build=true）');
  }

  stdout.writeln('开始编译 Inno 脚本生成安装包...');
  final innoExit = await runCommand(isccPath, [
    innoScriptPath,
  ], workingDirectory: projectRoot.path);
  if (innoExit != 0) {
    stderr.writeln('ISCC 编译失败，退出码：$innoExit');
    exitCode = innoExit;
    return;
  }

  final latest = findLatestInstallerExe(outputDir);
  if (latest == null) {
    stdout.writeln('已编译完成，但未在输出目录找到 .exe：${outputDir.path}');
    return;
  }

  stdout.writeln('已生成安装包：${latest.path}');
}
