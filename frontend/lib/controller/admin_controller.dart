import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AdminController {
  static const String baseUrl = 'http://localhost:3000/api/admin';
  static const Duration _timeout = Duration(seconds: 15);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ดึง JWT Token จาก Local Storage เพื่อสร้าง Header
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // ==========================================================================
  // 1. ดึงรายชื่อผู้ใช้ทั้งหมด (GET /api/admin/users)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/users'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
        return [];
      } else {
        final data = _safeDecodeMap(response.body);
        throw Exception(data['message'] ?? 'Unable to fetch users list');
      }
    } catch (e) {
      debugPrint('AdminController.getAllUsers error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 2. ระงับ / ปลดระงับบัญชีผู้ใช้ (PATCH /api/admin/users/:id/status)
  // ==========================================================================
  Future<Map<String, dynamic>> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/$userId/status'),
            headers: headers,
            body: jsonEncode({
              'is_active': isActive ? 1 : 0,
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to update user status');
      }
    } catch (e) {
      debugPrint('AdminController.updateUserStatus error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 3. ยืนยันตัวตนผู้ขาย KYC (PATCH /api/admin/users/:id/verify)
  // ==========================================================================
  Future<Map<String, dynamic>> verifySeller({
    required String userId,
    required bool isVerified,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/$userId/verify'),
            headers: headers,
            body: jsonEncode({
              'is_verified': isVerified ? 1 : 0,
            }),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Unable to update seller verification status',
        );
      }
    } catch (e) {
      debugPrint('AdminController.verifySeller error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 4. ลบบัญชีผู้ใช้ (DELETE /api/admin/users/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users/$userId'),
            headers: headers,
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to delete user');
      }
    } catch (e) {
      debugPrint('AdminController.deleteUser error: $e');
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