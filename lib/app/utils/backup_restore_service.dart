import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../data/local/db_helper.dart';

class BackupFileInfo {
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final DateTime modifiedAt;

  BackupFileInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.modifiedAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd hh:mm a').format(modifiedAt);
  }
}

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final String? fileName;
  final int? fileSizeBytes;
  final DateTime? createdAt;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.fileName,
    this.fileSizeBytes,
    this.createdAt,
  });

  String get formattedSize {
    final bytes = fileSizeBytes ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupInspectionResult {
  final bool isValid;
  final String? errorMessage;
  final String? filePath;
  final int fileSizeBytes;
  final int productsCount;
  final int salesCount;
  final int ordersCount;
  final int customersCount;
  final int usersCount;

  BackupInspectionResult({
    required this.isValid,
    this.errorMessage,
    this.filePath,
    this.fileSizeBytes = 0,
    this.productsCount = 0,
    this.salesCount = 0,
    this.ordersCount = 0,
    this.customersCount = 0,
    this.usersCount = 0,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class RestoreResult {
  final bool success;
  final String message;
  final BackupInspectionResult? inspection;

  RestoreResult({
    required this.success,
    required this.message,
    this.inspection,
  });
}

class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._internal();

  BackupRestoreService._internal();

  /// Dedicated local directory where backup snapshots are stored
  Future<Directory> getBackupDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File storage is not supported on web.');
    }

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final docDir = await getApplicationDocumentsDirectory();
        final backupDir = Directory(join(docDir.path, 'SnapCart', 'Backups'));
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return backupDir;
      } else {
        final appSupport = await getApplicationSupportDirectory();
        final backupDir = Directory(join(appSupport.path, 'Backups'));
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return backupDir;
      }
    } catch (_) {
      final fallbackDir = Directory(join(Directory.current.path, 'SnapCart_Backups'));
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
    }
  }

  /// Creates a timestamped .db backup copy of the current SQLite database
  Future<BackupResult> createBackup({String? customDestinationDir}) async {
    if (kIsWeb) {
      return BackupResult(
        success: false,
        message: 'Direct SQLite file backup is not supported on Web browsers.',
      );
    }

    try {
      // 1. Flush any pending transactions from WAL into main file
      await DBHelper.instance.flushWal();

      final sourcePath = await DBHelper.instance.getDatabasePath();
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        return BackupResult(
          success: false,
          message: 'Active SQLite database file not found at: $sourcePath',
        );
      }

      // 2. Target folder
      Directory destDir;
      if (customDestinationDir != null && customDestinationDir.isNotEmpty) {
        destDir = Directory(customDestinationDir);
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }
      } else {
        destDir = await getBackupDirectory();
      }

      // 3. Generate timestamped filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'snapcart_backup_$timestamp.db';
      final targetPath = join(destDir.path, fileName);

      // 4. Copy file
      await sourceFile.copy(targetPath);
      final targetFile = File(targetPath);
      final size = await targetFile.length();

      return BackupResult(
        success: true,
        message: 'Backup created successfully!',
        filePath: targetPath,
        fileName: fileName,
        fileSizeBytes: size,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create backup: $e',
      );
    }
  }

  /// Lists all local backup files sorted newest first
  Future<List<BackupFileInfo>> getLocalBackups() async {
    if (kIsWeb) return [];

    try {
      final dir = await getBackupDirectory();
      final entities = dir.listSync();
      final List<BackupFileInfo> backups = [];

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.db')) {
          final stat = entity.statSync();
          backups.add(BackupFileInfo(
            fileName: basename(entity.path),
            filePath: entity.path,
            fileSizeBytes: stat.size,
            modifiedAt: stat.modified,
          ));
        }
      }

      backups.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return backups;
    } catch (_) {
      return [];
    }
  }

  /// Inspects a candidate backup file to verify it is valid SQLite and reads key statistics
  Future<BackupInspectionResult> inspectBackupFile(String filePath) async {
    if (kIsWeb) {
      return BackupInspectionResult(
        isValid: false,
        errorMessage: 'Database inspection is not supported on Web.',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return BackupInspectionResult(
        isValid: false,
        errorMessage: 'The selected backup file does not exist.',
      );
    }

    final fileSize = await file.length();
    if (fileSize < 100) {
      return BackupInspectionResult(
        isValid: false,
        errorMessage: 'File is too small to be a valid SQLite database.',
      );
    }

    Database? db;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        db = await databaseFactoryFfi.openDatabase(
          filePath,
          options: OpenDatabaseOptions(readOnly: true),
        );
      } else {
        db = await openDatabase(
          filePath,
          readOnly: true,
        );
      }

      // Check SQLite integrity
      final integrityCheck = await db.rawQuery('PRAGMA integrity_check;');
      final integrityVal = integrityCheck.isNotEmpty
          ? integrityCheck.first.values.first.toString()
          : 'unknown';

      if (integrityVal.toLowerCase() != 'ok') {
        return BackupInspectionResult(
          isValid: false,
          errorMessage: 'Database integrity check failed: $integrityVal',
          filePath: filePath,
          fileSizeBytes: fileSize,
        );
      }

      int productsCount = 0;
      int salesCount = 0;
      int ordersCount = 0;
      int customersCount = 0;
      int usersCount = 0;

      try {
        final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM products');
        productsCount = (res.first['cnt'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      try {
        final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM sales_orders');
        salesCount = (res.first['cnt'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      try {
        final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM customer_orders');
        ordersCount = (res.first['cnt'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      try {
        final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM customers');
        customersCount = (res.first['cnt'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      try {
        final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM users');
        usersCount = (res.first['cnt'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      return BackupInspectionResult(
        isValid: true,
        filePath: filePath,
        fileSizeBytes: fileSize,
        productsCount: productsCount,
        salesCount: salesCount,
        ordersCount: ordersCount,
        customersCount: customersCount,
        usersCount: usersCount,
      );
    } catch (e) {
      return BackupInspectionResult(
        isValid: false,
        errorMessage: 'Unable to open or read SQLite backup: $e',
        filePath: filePath,
        fileSizeBytes: fileSize,
      );
    } finally {
      await db?.close();
    }
  }

  /// Restores the database with automatic pre-flight safety snapshot and rollback protection
  Future<RestoreResult> restoreDatabase(String backupFilePath) async {
    if (kIsWeb) {
      return RestoreResult(
        success: false,
        message: 'Direct SQLite file restore is not supported on Web.',
      );
    }

    // 1. Verify candidate file
    final inspection = await inspectBackupFile(backupFilePath);
    if (!inspection.isValid) {
      return RestoreResult(
        success: false,
        message: inspection.errorMessage ?? 'Invalid database file.',
      );
    }

    final targetDbPath = await DBHelper.instance.getDatabasePath();
    final targetFile = File(targetDbPath);
    final rollbackFile = File('$targetDbPath.pre_restore_bak');

    try {
      // 2. Flush WAL on current database
      await DBHelper.instance.flushWal();

      // 3. Create rollback safety copy
      if (await targetFile.exists()) {
        await targetFile.copy(rollbackFile.path);
      }

      // 4. Safely close active connection
      await DBHelper.instance.closeDatabase();
      await Future.delayed(const Duration(milliseconds: 250));

      // 5. Remove stale WAL & SHM companions
      final walFile = File('$targetDbPath-wal');
      final shmFile = File('$targetDbPath-shm');
      if (await walFile.exists()) {
        try { await walFile.delete(); } catch (_) {}
      }
      if (await shmFile.exists()) {
        try { await shmFile.delete(); } catch (_) {}
      }

      // 6. Overwrite active DB with selected backup file
      final backupFile = File(backupFilePath);
      await backupFile.copy(targetDbPath);

      // 7. Reopen database and execute migrations if needed
      await DBHelper.instance.reopenDatabase();

      // 8. Delete rollback safety file on success
      if (await rollbackFile.exists()) {
        try { await rollbackFile.delete(); } catch (_) {}
      }

      return RestoreResult(
        success: true,
        message: 'Database restored successfully!',
        inspection: inspection,
      );
    } catch (e) {
      // Automatic safety rollback
      try {
        if (await rollbackFile.exists()) {
          await rollbackFile.copy(targetDbPath);
          await DBHelper.instance.reopenDatabase();
          await rollbackFile.delete();
        }
      } catch (_) {}

      return RestoreResult(
        success: false,
        message: 'Restore failed: $e. Reverted safely to original database state.',
      );
    }
  }

  /// Deletes a local backup file
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
