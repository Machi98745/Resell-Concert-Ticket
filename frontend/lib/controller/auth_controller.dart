import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthController {
  static const String baseUrl = 'http://localhost:3000/api/auth';
  static const Duration _timeout = Duration(seconds: 15);

  // ==========================================================================
  // 1. ฟังก์ชันเข้าสู่ระบบ (POST /api/auth/login)
  // ==========================================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw Exception('Please enter your username and password.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'Your account has been suspended');
      } else {
        throw Exception(data['message'] ?? 'Invalid username or password');
      }
    } catch (e) {
      debugPrint('AuthController.login error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 2. ฟังก์ชันสมัครสมาชิก (POST /api/auth/register)
  // ==========================================================================
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (fullName.trim().isEmpty ||
        username.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty) {
      throw Exception('Please fill in all required fields.');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'full_name': fullName.trim(),
              'username': username.trim(),
              'email': email.trim(),
              'password': password,
              'phone': phone?.trim(),
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to register as a new user');
      }
    } catch (e) {
      debugPrint('AuthController.register error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 3. ฟังก์ชันดึงข้อมูลผู้ใช้ปัจจุบันและสถานะยืนยันตัวตน (GET /api/auth/me)
  // ==========================================================================
  Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/me'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to fetch profile data');
      }
    } catch (e) {
      debugPrint('AuthController.getMe error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 4. ฟังก์ชันแก้ไขโปรไฟล์ (PUT /api/auth/profile)
  // ==========================================================================
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String email,
    String? phone,
  }) async {
    if (fullName.trim().isEmpty || email.trim().isEmpty) {
      throw Exception('Full name and email are required.');
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'full_name': fullName.trim(),
              'email': email.trim(),
              'phone': phone?.trim(),
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to update profile');
      }
    } catch (e) {
      debugPrint('AuthController.updateProfile error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ฟังก์ชันเปลี่ยนรหัสผ่านเมื่อล็อกอินอยู่ (PUT /api/auth/change-password)
  // ==========================================================================
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Please provide both current and new password.');
    }

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/change-password'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to change password');
      }
    } catch (e) {
      debugPrint('AuthController.changePassword error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 6. ฟังก์ชันรีเซ็ตรหัสผ่านกรณีลืมรหัสผ่าน (POST /api/auth/reset-password)
  // ==========================================================================
  Future<void> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    if (email.trim().isEmpty || phone.trim().isEmpty || newPassword.isEmpty) {
      throw Exception('Please provide email, phone number, and new password.');
    }

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'email': email.trim(),
              'phone': phone.trim(),
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Unable to reset password');
      }
    } catch (e) {
      debugPrint('AuthController.resetPassword error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  Map<String, dynamic> _safeDecodeMap(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  String _cleanErrorMessage(Object error) {
    final msg = error.toString().replaceAll('Exception: ', '').trim();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('ClientException') ||
        msg.contains('TimeoutException')) {
      return 'Unable to connect to the server. Please check the Backend service.';
    }
    if (msg.contains('FormatException')) {
      return 'Invalid response from server.';
    }
    return msg;
  }
}
