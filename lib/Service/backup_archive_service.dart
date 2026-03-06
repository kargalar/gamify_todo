import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'package:next_level/Service/logging_service.dart';

class BackupArchiveService {
  static const String backupJsonFileName = 'gamify_todo_backup.json';
  static const String attachmentsFolderName = 'attachments';

  Future<void> createZipFromDirectory({
    required Directory sourceDirectory,
    required String zipFilePath,
  }) async {
    final zipFile = File(zipFilePath);
    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);

    try {
      await for (final entity in sourceDirectory.list(recursive: true, followLinks: false)) {
        if (entity is! File) {
          continue;
        }

        if (!await entity.exists()) {
          LogService.error('⚠️ BackupArchiveService: Skipping missing file during zip: ${entity.path}');
          continue;
        }

        final relativePath = path.relative(entity.path, from: sourceDirectory.path);

        try {
          encoder.addFile(entity, relativePath);
        } catch (e) {
          LogService.error('❌ BackupArchiveService: Failed to add file to zip: ${entity.path} - $e');
          if (path.basename(entity.path) == backupJsonFileName) {
            rethrow;
          }
        }
      }
    } finally {
      encoder.close();
    }

    if (!await zipFile.exists() || await zipFile.length() == 0) {
      throw Exception('Backup archive could not be created.');
    }
  }

  Future<File?> findBackupJsonFile(Directory extractedRoot) async {
    if (!await extractedRoot.exists()) {
      return null;
    }

    await for (final entity in extractedRoot.list(recursive: true, followLinks: false)) {
      if (entity is File && path.basename(entity.path) == backupJsonFileName) {
        return entity;
      }
    }

    return null;
  }

  Future<Directory?> findAttachmentsDirectory({
    required Directory extractedRoot,
    Directory? preferredRoot,
  }) async {
    if (preferredRoot != null) {
      final preferredAttachmentsDir = Directory(path.join(preferredRoot.path, attachmentsFolderName));
      if (await preferredAttachmentsDir.exists()) {
        return preferredAttachmentsDir;
      }
    }

    if (!await extractedRoot.exists()) {
      return null;
    }

    await for (final entity in extractedRoot.list(recursive: true, followLinks: false)) {
      if (entity is Directory && path.basename(entity.path) == attachmentsFolderName) {
        return entity;
      }
    }

    return null;
  }

  Future<Map<String, String>> restoreAttachments({
    required Directory sourceDirectory,
    required Directory destinationDirectory,
  }) async {
    final restoredFiles = <String, String>{};

    if (!await sourceDirectory.exists()) {
      return restoredFiles;
    }

    await destinationDirectory.create(recursive: true);

    await for (final entity in sourceDirectory.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      if (!await entity.exists()) {
        LogService.error('⚠️ BackupArchiveService: Attachment disappeared before restore: ${entity.path}');
        continue;
      }

      final fileName = path.basename(entity.path);
      final restoredPath = path.join(destinationDirectory.path, fileName);
      final restoredFile = await entity.copy(restoredPath);
      restoredFiles[fileName] = restoredFile.path;
    }

    return restoredFiles;
  }
}
