import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

class BackupService {
  /// Create complete backup archive (SQLite JSON data + generated documents)
  static Future<String> createBackupArchive() async {
    final dbData = await AppDatabase.instance.exportAllData();
    final jsonStr = jsonEncode(dbData);

    final archive = Archive();
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('database_dump.json', jsonBytes.length, jsonBytes));

    // Also include generated documents if any
    if (!kIsWeb) {
      final docsDir = await getApplicationDocumentsDirectory();
      final amcDocsFolder = Directory('${docsDir.path}/AMC_Documents');
      if (await amcDocsFolder.exists()) {
        final files = amcDocsFolder.listSync();
        for (final f in files) {
          if (f is File) {
            final filename = f.path.split(Platform.pathSeparator).last;
            final bytes = await f.readAsBytes();
            archive.addFile(ArchiveFile('documents/$filename', bytes.length, bytes));
          }
        }
      }
    }

    final zipData = ZipEncoder().encode(archive);

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFileName = 'amc_manager_backup_$dateStr.amcbak';

    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/$backupFileName');
      await backupFile.writeAsBytes(zipData, flush: true);
      return backupFile.path;
    }
    return backupFileName;
  }

  /// Share or save backup file
  static Future<void> shareBackupFile(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'AMC Manager Offline Backup',
        text: 'Complete offline database and documents backup for AMC Manager.',
      ),
    );
  }

  /// Restore from backup file picked by user
  static Future<bool> restoreFromBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return false;
    }

    final path = result.files.first.path;
    if (path == null) return false;

    final file = File(path);
    final bytes = await file.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? dbFile;

    for (final f in archive.files) {
      if (f.name == 'database_dump.json') {
        dbFile = f;
      } else if (f.name.startsWith('documents/')) {
        // Restore document
        final filename = f.name.replaceFirst('documents/', '');
        if (filename.isNotEmpty) {
          final docsDir = await getApplicationDocumentsDirectory();
          final targetFile = File('${docsDir.path}/AMC_Documents/$filename');
          await targetFile.create(recursive: true);
          await targetFile.writeAsBytes(f.content as List<int>);
        }
      }
    }

    if (dbFile != null) {
      final jsonStr = utf8.decode(dbFile.content as List<int>);
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      await AppDatabase.instance.restoreAllData(data);
      return true;
    }

    return false;
  }
}
