import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthController {
  static const String baseURL = 'http://localhost:3000/api/auth';

  // ==========================================================================
  // 1. ฟังก์ชันเข้าสู่ระบบ (POST /api/auth/login)
  // ==========================================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw Exception('Please enter your username and password.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseURL/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else if (response.statusCode == 403) {
        throw Exception(data['message'] ?? 'Your account has been suspended');
      } else {
        throw Exception(data['message'] ?? 'Invalid username or password');
      }
    } catch (e) {
      debugPrint('AuthController.login error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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

    try {
      final response = await http.post(
        Uri.parse('$baseURL/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'full_name': fullName.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'phone': phone?.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to register as a new user');
      }
    } catch (e) {
      debugPrint('AuthController.register error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==========================================================================
  // 3. ฟังก์ชันดึงข้อมูลผู้ใช้ปัจจุบันและสถานะยืนยันตัวตน (GET /api/auth/me)
  // ==========================================================================
  Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseURL/me'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to fetch profile data');
      }
    } catch (e) {
      debugPrint('AuthController.getMe error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==========================================================================
  // 4. ฟังก์ชันรีเซ็ตรหัสผ่าน (Reset Password)
  // ==========================================================================
  Future<void> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/reset-password'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'phone': phone,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Unable to reset password');
      }
    } catch (e) {
      debugPrint('AuthController.resetPassword error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}