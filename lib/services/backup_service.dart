import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BackupService {
  static const _maxBackups = 5;
  static const _folderName = 'WarraichPetroleum';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _account;

  Future<Map<String, String>> _getHeaders() async {
    _account ??= await _googleSignIn.signIn();
    if (_account == null) return {};
    final auth = await _account!.authentication;
    return {
      'Authorization': 'Bearer ${auth.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  Future<String?> _getFolderId() async {
    final headers = await _getHeaders();
    if (headers.isEmpty) return null;

    final response = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files?q=name%3D%27$_folderName%27%20and%20mimeType%3D%27application%2Fvnd.google-apps.folder%27%20and%20trashed%3Dfalse'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = data['files'] as List? ?? [];
      if (files.isNotEmpty) return files[0]['id'];
    }

    return await _createFolder(headers);
  }

  Future<String?> _createFolder(Map<String, String> headers) async {
    final metadata = jsonEncode({
      'name': _folderName,
      'mimeType': 'application/vnd.google-apps.folder',
    });

    final response = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: headers,
      body: metadata,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    }
    return null;
  }

  Future<bool> backupDatabase(File dbFile) async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) return false;

      final folderId = await _getFolderId();
      if (folderId == null) return false;

      final fileName = 'warraich_backup_${DateTime.now().millisecondsSinceEpoch}.db';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
      );

      request.headers.addAll({
        'Authorization': headers['Authorization']!,
      });

      final metadata = jsonEncode({
        'name': fileName,
        'parents': [folderId],
      });

      request.files.add(http.MultipartFile.fromString(
        'metadata',
        metadata,
        contentType: MediaType('application', 'json'),
      ));
      request.files.add(
        await http.MultipartFile.fromPath('file', dbFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await _enforceMaxBackups(folderId, headers);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _enforceMaxBackups(String folderId, Map<String, String> headers) async {
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files?q=%27$folderId%27%20in%20parents%20and%20name%20contains%20%27warraich_backup_%27%20and%20trashed%3Dfalse&orderBy=createdTime%20desc'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = data['files'] as List? ?? [];
      if (files.length > _maxBackups) {
        for (final file in files.sublist(_maxBackups)) {
          await http.delete(
            Uri.parse('https://www.googleapis.com/drive/v3/files/${file['id']}'),
            headers: headers,
          );
        }
      }
    }
  }

  Future<bool> restoreLatestBackup() async {
    try {
      final headers = await _getHeaders();
      if (headers.isEmpty) return false;

      final folderId = await _getFolderId();
      if (folderId == null) return false;

      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?q=%27$folderId%27%20in%20parents%20and%20name%20contains%20%27warraich_backup_%27%20and%20trashed%3Dfalse&orderBy=createdTime%20desc&pageSize=1'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List? ?? [];
        if (files.isEmpty) return false;

        final fileId = files[0]['id'];
        final downloadResponse = await http.get(
          Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
          headers: headers,
        );

        if (downloadResponse.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File(p.join(dir.path, 'warraich_petroleum.db'));
          await file.writeAsBytes(downloadResponse.bodyBytes);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  Future<bool> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      return _account != null;
    } catch (e) {
      return false;
    }
  }
}
