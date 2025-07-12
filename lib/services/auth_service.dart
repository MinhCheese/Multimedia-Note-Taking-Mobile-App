import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_login_response.dart';
import 'package:thuc_tap/models/user_register_dto.dart';
class AuthService {
  //Test may that 'http://192.168.100.29:5023' va dotnet run --urls=http://0.0.0.0:5023
  //test may ao 'http://10.0.2.2:5023'
  static const String baseUrl = 'http://192.168.100.29:5023';

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
        return UserLoginResponse.fromJson(jsonData);
      } else {
        print('Login failed: ${response.statusCode}');
        print('Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
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
        print('Đăng ký thất bại: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Lỗi: $e');
      return false;
    }
  }

}
