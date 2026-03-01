/// 文件用途：备份文件存储（应用私有目录托管备份历史/快照），包含原子写入与临时文件清理。
/// 作者：Codex
/// 创建日期：2026-02-28
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 备份存储服务。
///
/// 说明（与 spec 一致）：
/// - 默认导出到应用私有目录（纳入备份历史，可枚举/可删除）
/// - 覆盖导入前快照保存到 snapshots/（仅保留最近 1 份，覆盖式）
/// - 写入使用“临时文件 + 原子替换”，避免中断产生半成品
class BackupStorage {
  /// 构造函数。
  ///
  /// 参数：
  /// - [baseDir] 可选的基础目录（用于测试注入）；为空时使用应用支持目录（ApplicationSupportDirectory）。
  const BackupStorage({Directory? baseDir}) : _baseDir = baseDir;

  final Directory? _baseDir;

  static const String backupsDirName = 'backups';
  static const String snapshotsDirName = 'snapshots';

  /// 获取应用私有基础目录。
  Future<Directory> getBaseDir() async {
    final dir = _baseDir;
    if (dir != null) return dir;
    return getApplicationSupportDirectory();
  }

  /// 获取备份历史目录（不存在则创建）。
  Future<Directory> getBackupsDir() async {
    final base = await getBaseDir();
    final dir = Directory(p.join(base.path, backupsDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 获取快照目录（不存在则创建）。
  Future<Directory> getSnapshotsDir() async {
    final base = await getBaseDir();
    final dir = Directory(p.join(base.path, snapshotsDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 清理遗留的临时文件（*.tmp）。
  ///
  /// 说明：用于满足“可中断/可取消”验收要求：中断后只会残留临时文件，下次启动/进入页面时清理。
  Future<void> cleanupTempFiles() async {
    Future<void> cleanupIn(Directory dir) async {
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.tmp')) {
          try {
            await entity.delete();
          } catch (_) {
            // 清理失败不阻塞主流程（可能被系统占用/权限限制）。
          }
        }
      }
    }

    await cleanupIn(await getBackupsDir());
    await cleanupIn(await getSnapshotsDir());
  }

  /// 写入备份文件到备份历史目录（原子写入）。
  ///
  /// 返回值：最终文件（位于 backups/）。
  Future<File> writeBackupFile({
    required String fileName,
    required String content,
  }) async {
    final dir = await getBackupsDir();
    final target = File(p.join(dir.path, fileName));
    return _writeAtomically(target: target, content: content);
  }

  /// 写入导入前快照（覆盖式，仅保留 1 份）。
  ///
  /// 返回值：最终文件（位于 snapshots/）。
  Future<File> writeSnapshotFile({
    required String fileName,
    required String content,
  }) async {
    final dir = await getSnapshotsDir();
    final target = File(p.join(dir.path, fileName));
    return _writeAtomically(target: target, content: content);
  }

  /// 列出备份历史文件（按修改时间倒序）。
  Future<List<File>> listBackupFiles() async {
    final dir = await getBackupsDir();
    if (!await dir.exists()) return const <File>[];

    final files = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.yikebackup')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// 获取当前快照文件（若不存在则返回 null）。
  Future<File?> getSnapshotFile(String fileName) async {
    final dir = await getSnapshotsDir();
    final file = File(p.join(dir.path, fileName));
    if (!await file.exists()) return null;
    return file;
  }

  /// 列出快照目录下的文件（按修改时间倒序）。
  Future<List<File>> listSnapshotFiles() async {
    final dir = await getSnapshotsDir();
    if (!await dir.exists()) return const <File>[];

    final files = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.yikebackup')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// 删除指定备份文件（仅允许删除 backups/ 下的文件）。
  Future<void> deleteBackupFile(File file) async {
    final dir = await getBackupsDir();
    final normalizedDir = p.normalize(dir.path);
    final normalizedFile = p.normalize(file.path);
    if (!p.isWithin(normalizedDir, normalizedFile)) {
      throw ArgumentError('不允许删除备份目录外的文件');
    }
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _writeAtomically({
    required File target,
    required String content,
  }) async {
    final dir = target.parent;
    if (!await dir.exists()) await dir.create(recursive: true);

    // 临时文件与目标文件同目录，保证 rename 的原子性（尽可能）。
    final tmp = File('${target.path}.tmp');

    // 先清理上次残留的 tmp，避免 Windows 上被占用导致 rename 失败。
    if (await tmp.exists()) {
      try {
        await tmp.delete();
      } catch (_) {
        // 若删除失败，则换一个随机临时文件名，避免阻塞主流程。
      }
    }

    final effectiveTmp = await tmp.exists()
        ? File('${target.path}.${DateTime.now().millisecondsSinceEpoch}.tmp')
        : tmp;

    await effectiveTmp.writeAsString(content, flush: true);

    // Windows：rename 目标存在会失败；先删除再替换。
    if (await target.exists()) {
      await target.delete();
    }
    return effectiveTmp.rename(target.path);
  }
}
