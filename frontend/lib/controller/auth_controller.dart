import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthController {
  static const String baseURL = 'http://localhost:3000/api/auth';

  // 1. ฟังก์ชันเข้าสู่ระบบ (Login)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 2. ฟังก์ชันรีเซ็ตรหัสผ่าน (Reset Password)
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
        throw Exception(response.body);
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}