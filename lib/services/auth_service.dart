import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Thêm thư viện này
import '../models/user_login_response.dart';
import 'package:thuc_tap/models/user_register_dto.dart';

class AuthService {
  static const String baseUrl = 'http://10.123.142.19:5023';

  static Future<UserLoginResponse?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final loginResponse = UserLoginResponse.fromJson(jsonData);

        // 1. LƯU TOKEN LẠI ĐỂ DUY TRÌ ĐĂNG NHẬP
        final prefs = await SharedPreferences.getInstance();
        // Giả sử trong model UserLoginResponse của Chi có trường 'token'
        if (loginResponse.token != null) {
          await prefs.setString('jwt_token', loginResponse.token!);
        }

        return loginResponse;
      } else {
        // 2. TRẢ VỀ LỖI CHI TIẾT TỪ BACKEND ĐỂ UI HIỂN THỊ
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Bắt lỗi kết nối mạng (timeout, sập server, v.v.)
      print('Login Exception: $e');
      throw Exception('Không thể kết nối đến máy chủ. Lỗi: $e');
    }
  }

  static Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Đăng ký thất bại.');
      }
    } catch (e) {
      print('Register Exception: $e');
      throw Exception('Không thể kết nối đến máy chủ. Lỗi: $e');
    }
  }

  // Bổ sung hàm đăng xuất để xóa Token
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}