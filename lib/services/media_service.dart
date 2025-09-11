import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thuc_tap/models/note_model.dart';

class MediaService {
  static const String baseUrl = 'http://192.168.100.29:5023';

  static Future<List<MediaFile>> fetchMediaFiles(String userId) async {
    final url = Uri.parse('$baseUrl/api/media/user/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((item) => MediaFile.fromJson(item))
            .where((file) => file.isDeleted == false) // lọc ở đây!
            .toList();
      } else {
        print('Lỗi khi tải media files: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi ngoại lệ: $e');
      return [];
    }
  }

  static Future<void> renameAudioFile(String mediaId, String newDisplayName) async {
    final url = Uri.parse('$baseUrl/api/media/$mediaId/rename');

    final body = json.encode({
      'newDisplayName': newDisplayName, // phải dùng đúng key "newDisplayName"
    });

    print('Sending PUT to $url with body: $body');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*', // thêm dòng này nếu cần tương thích với backend
      },
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 204) {
      print('Rename successful');
    } else {
      print('Rename failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to rename audio file');
    }
  }


}
