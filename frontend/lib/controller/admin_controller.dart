import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminController {
  AdminController({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseUrl = 'http://localhost:3000/api/admin';
  static const Duration _timeout = Duration(seconds: 15);

  // ==========================================================================
  // 1. Business Logic: ตรวจสอบความถูกต้องของสิทธิ์และพารามิเตอร์แอดมิน (Validation)
  // ==========================================================================
  static String? validateAdminAction({
    required String token,
    required int? userId,
    int? currentAdminId,
    bool preventSelfAction = false,
  }) {
    if (token.trim().isEmpty) {
      return 'Please log in as an administrator';
    }

    if (userId == null || userId <= 0) {
      return 'Invalid user ID';
    }

    if (preventSelfAction &&
        currentAdminId != null &&
        userId == currentAdminId) {
      return 'Admin cannot suspend or delete their own account';
    }

    return null;
  }

  // ==========================================================================
  // 2. ดึงรายชื่อผู้ใช้ทั้งหมด พร้อมยอดตั๋วที่ขาย/ซื้อ (GET /api/admin/users)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Please log in as an administrator');
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/users'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer ${token.trim()}',
            },
          )
          .timeout(_timeout);

      final dynamic body = _safeDecode(response.body);

      if (response.statusCode == 200) {
        if (body is List) {
          return body.cast<Map<String, dynamic>>();
        } else if (body is Map && body['data'] is List) {
          return (body['data'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to fetch user list');
      }
    } catch (e) {
      debugPrint('AdminController.getAllUsers error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 3. ระงับ / ปลดระงับบัญชีผู้ใช้ (PATCH /api/admin/users/:id/status)
  // ==========================================================================
  Future<Map<String, dynamic>> updateUserStatus({
    required String token,
    required int userId,
    required bool isActive,
    int? currentAdminId,
  }) async {
    final validationError = validateAdminAction(
      token: token,
      userId: userId,
      currentAdminId: currentAdminId,
      preventSelfAction: !isActive,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/users/$userId/status'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer ${token.trim()}',
            },
            body: jsonEncode({
              'is_active': isActive ? 1 : 0,
            }),
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = _safeDecodeMap(response.body);

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
  // 4. ยืนยันตัวตนผู้ขาย KYC (PATCH /api/admin/users/:id/verify)
  // ==========================================================================
  Future<Map<String, dynamic>> verifySeller({
    required String token,
    required int userId,
    required bool isVerified,
  }) async {
    final validationError = validateAdminAction(
      token: token,
      userId: userId,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/users/$userId/verify'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer ${token.trim()}',
            },
            body: jsonEncode({
              'is_verified': isVerified ? 1 : 0,
            }),
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to update seller verification');
      }
    } catch (e) {
      debugPrint('AdminController.verifySeller error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ลบบัญชีผู้ใช้ (DELETE /api/admin/users/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> deleteUser({
    required String token,
    required int userId,
    int? currentAdminId,
  }) async {
    final validationError = validateAdminAction(
      token: token,
      userId: userId,
      currentAdminId: currentAdminId,
      preventSelfAction: true,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/users/$userId'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer ${token.trim()}',
            },
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = _safeDecodeMap(response.body);

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

  // ==========================================================================
  // Helper: แปลง JSON และจัดการข้อความ Error
  // ==========================================================================
  dynamic _safeDecode(String rawBody) {
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      throw const FormatException('Invalid response from server.');
    }
  }

  Map<String, dynamic> _safeDecodeMap(String rawBody) {
    final decoded = _safeDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Invalid response format from server.');
  }

  String _cleanErrorMessage(Object error) {
    final String msg = error.toString().replaceAll('Exception: ', '').trim();
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
