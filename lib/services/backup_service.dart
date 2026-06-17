import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../config/app_config.dart';
import 'auth_service.dart';

class BackupService {
  static const _maxBackups = 5;
  static const _folderName = 'WarraichPetroleum';
  static const _httpTimeout = Duration(seconds: 60);

  final AuthService _authService;

  BackupService(this._authService);

  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await _authService.getDriveAccessToken();
      if (token == null || token.isEmpty) return {};
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      log('backup: _getHeaders error: $e');
      return {};
    }
  }

  Future<bool> signIn() async {
    if (!AppConfig.isGoogleDriveConfigured) return false;
    try {
      final credential = await _authService.signInWithGoogle();
      return credential != null;
    } catch (e) {
      log('backup: signIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<String?> _getFolderId() async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) return null;

      final response = await http
          .get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files?q=name%3D%27$_folderName%27%20and%20mimeType%3D%27application%2Fvnd.google-apps.folder%27%20and%20trashed%3Dfalse',
            ),
            headers: headers,
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List? ?? [];
        if (files.isNotEmpty) return files[0]['id'];
      }

      return await _createFolder(headers);
    } catch (e) {
      log('backup: _getFolderId error: $e');
      return null;
    }
  }

  Future<String?> _createFolder(Map<String, String> headers) async {
    try {
      final metadata = jsonEncode({
        'name': _folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      });

      final response = await http
          .post(
            Uri.parse('https://www.googleapis.com/drive/v3/files'),
            headers: headers,
            body: metadata,
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
      return null;
    } catch (e) {
      log('backup: _createFolder error: $e');
      return null;
    }
  }

  Future<bool> backupDatabase(File dbFile) async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) return false;

      final folderId = await _getFolderId();
      if (folderId == null) return false;

      final fileName =
          'warraich_backup_${DateTime.now().millisecondsSinceEpoch}.db';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        ),
      );

      request.headers.addAll({'Authorization': headers['Authorization']!});

      final metadata = jsonEncode({
        'name': fileName,
        'parents': [folderId],
      });

      request.files.add(
        http.MultipartFile.fromString(
          'metadata',
          metadata,
          contentType: MediaType('application', 'json'),
        ),
      );
      request.files.add(await http.MultipartFile.fromPath('file', dbFile.path));

      final streamedResponse = await request.send().timeout(_httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await _enforceMaxBackups(folderId, headers);
        return true;
      }
      return false;
    } catch (e) {
      log('backup: backupDatabase error: $e');
      return false;
    }
  }

  Future<void> _enforceMaxBackups(
    String folderId,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files?q=%27$folderId%27%20in%20parents%20and%20name%20contains%20%27warraich_backup_%27%20and%20trashed%3Dfalse&orderBy=createdTime%20desc',
            ),
            headers: headers,
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List? ?? [];
        if (files.length > _maxBackups) {
          for (final file in files.sublist(_maxBackups)) {
            await http
                .delete(
                  Uri.parse(
                    'https://www.googleapis.com/drive/v3/files/${file['id']}',
                  ),
                  headers: headers,
                )
                .timeout(_httpTimeout);
          }
        }
      }
    } catch (e) {
      log('backup: _enforceMaxBackups error: $e');
    }
  }

  Future<File?> restoreLatestBackup() async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) return null;

      final folderId = await _getFolderId();
      if (folderId == null) return null;

      final response = await http
          .get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files?q=%27$folderId%27%20in%20parents%20and%20name%20contains%20%27warraich_backup_%27%20and%20trashed%3Dfalse&orderBy=createdTime%20desc&pageSize=1',
            ),
            headers: headers,
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List? ?? [];
        if (files.isEmpty) return null;

        final fileId = files[0]['id'];
        final downloadResponse = await http
            .get(
              Uri.parse(
                'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
              ),
              headers: headers,
            )
            .timeout(_httpTimeout);

        if (downloadResponse.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final tempPath = p.join(
            dir.path,
            'restore_${DateTime.now().millisecondsSinceEpoch}.db',
          );
          final file = File(tempPath);
          await file.writeAsBytes(downloadResponse.bodyBytes);
          return file;
        }
      }
      return null;
    } catch (e) {
      log('backup: restoreLatestBackup error: $e');
      return null;
    }
  }

  Future<List<Map<String, String>>> listBackups() async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) return [];

      final folderId = await _getFolderId();
      if (folderId == null) return [];

      final response = await http
          .get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files?q=%27$folderId%27%20in%20parents%20and%20name%20contains%20%27warraich_backup_%27%20and%20trashed%3Dfalse&orderBy=createdTime%20desc&fields=files(id,name,createdTime)',
            ),
            headers: headers,
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List? ?? [];
        return files
            .map<Map<String, String>>(
              (f) => {
                'id': f['id'] as String,
                'name': f['name'] as String,
                'createdTime': f['createdTime'] as String,
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      log('backup: listBackups error: $e');
      return [];
    }
  }

  Future<File?> restoreFromId(String fileId) async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) {
        log('backup: restoreFromId failed - no auth headers');
        return null;
      }
      log('backup: restoreFromId downloading $fileId...');
      final downloadResponse = await http
          .get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
            ),
            headers: headers,
          )
          .timeout(_httpTimeout);

      log('backup: restoreFromId status=${downloadResponse.statusCode}');
      if (downloadResponse.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final tempPath = p.join(
          dir.path,
          'restore_${DateTime.now().millisecondsSinceEpoch}.db',
        );
        final file = File(tempPath);
        await file.writeAsBytes(downloadResponse.bodyBytes);
        log(
          'backup: restoreFromId wrote ${downloadResponse.bodyBytes.length} bytes to temp',
        );
        return file;
      }
      log('backup: restoreFromId HTTP ${downloadResponse.statusCode}');
      return null;
    } catch (e) {
      log('backup: restoreFromId error: $e');
      return null;
    }
  }

  static const _localBackupsDir = 'backups';

  Future<bool> localBackup(File dbFile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(p.join(dir.path, _localBackupsDir));
      await backupsDir.create(recursive: true);

      final fileName =
          'warraich_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      final destPath = p.join(backupsDir.path, fileName);
      try {
        await dbFile.copy(destPath);
      } catch (_) {
        try {
          await File(destPath).delete();
        } catch (_) {}
        return false;
      }

      final files = backupsDir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final f in files.skip(_maxBackups)) {
        await f.delete();
      }
      return true;
    } catch (e) {
      log('backup: localBackup error: $e');
      return false;
    }
  }

  Future<File?> localRestore() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(p.join(dir.path, _localBackupsDir));
      if (!backupsDir.existsSync()) return null;

      final files = backupsDir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      if (files.isEmpty) return null;

      final latest = files.first;
      final tempPath = p.join(
        dir.path,
        'restore_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      await latest.copy(tempPath);
      return File(tempPath);
    } catch (e) {
      log('backup: localRestore error: $e');
      return null;
    }
  }
}
