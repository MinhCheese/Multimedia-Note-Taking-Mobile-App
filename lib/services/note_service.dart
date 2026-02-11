import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thuc_tap/models/note_model.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
class NoteService {
  //Test may that 'http://192.168.100.29:5023'
  //test may ao 'http://10.0.2.2:5023'
  static const String baseUrl = 'http://192.168.100.29:5023';

  static Future<List<NoteModel>> fetchNotesByUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/Notes/user/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((note) => NoteModel.fromJson(note)).toList();
    } else {
      throw Exception('Failed to load notes');
    }
  }

  static Future<bool> createNote({
    required String token,
    required String userId,
    required String title,
    required String content,
    required List<String> tags,
    DateTime? reminderAt,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'content': content,
        'tags': tags,
        'reminderAt': reminderAt?.toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      print('Failed to create note: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateNote({
    required String token,
    required String noteId,
    required String title,
    required String content,
    required List<String> tags,
    DateTime? reminderAt,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Notes/$noteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'tags': tags,
        'reminderAt': reminderAt?.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to update note: ${response.statusCode}');
      print('Response body: ${response.body}');
    }

    return response.statusCode == 200;
  }

  static Future<bool> deleteNote({
    required String token,
    required String noteId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/Notes/$noteId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Xoá ghi chú thành công: $noteId (status: ${response.statusCode})');
        return true;
      } else {
        print('❌ Lỗi xoá ghi chú: ${response.statusCode}');
        print('❌ Phản hồi từ server: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi khi gửi yêu cầu xoá: $e');
      return false;
    }
  }



  static Future<Map<String, dynamic>?> uploadAudioFile({
    required String token,
    required String noteId,
    required String filePath,
    required String displayName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/notes/upload-audio');

    final file = File(filePath);
    if (!file.existsSync()) {
      print('❌ File không tồn tại tại: $filePath');
      return null;
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['noteId'] = noteId
      ..fields['displayName'] = displayName
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('audio', 'aac'),
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      print('✅ Upload thành công, server trả về: $data');
      return data;
    } else {
      final error = await response.stream.bytesToString();
      print('❌ Upload thất bại: ${response.statusCode}');
      print('❌ Phản hồi từ server: $error');
      return null;
    }
  }



  static Future<String?> getLatestNoteId(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Notes/latest/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['noteId'];
    } else {
      print('Lỗi lấy noteId: ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadImageFile({
    required String token,
    required String noteId,
    required String filePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/notes/upload-image');

    final file = File(filePath);
    if (!file.existsSync()) {
      print('❌ File ảnh không tồn tại tại: $filePath');
      return null;
    }

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['noteId'] = noteId
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('image', 'jpeg'), // hoặc 'png' nếu bạn chắc định dạng
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      print('✅ Upload ảnh thành công, server trả về: $data');
      return data;
    } else {
      final error = await response.stream.bytesToString();
      print('❌ Upload ảnh thất bại: ${response.statusCode}');
      print('❌ Phản hồi từ server: $error');
      return null;
    }
  }

  static Future<bool> deleteMediaFile({
    required String token,
    required String filePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/notes/delete-media');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'filePath': filePath}),
    );

    return response.statusCode == 200;
  }

  static Future<NoteModel?> getNoteById(String token, String noteId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notes/$noteId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return NoteModel.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

}
