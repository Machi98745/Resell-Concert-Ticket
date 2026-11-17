import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminController {
  static const String baseUrl = 'http://localhost:3000/api/admin';
  static const Duration _timeout = Duration(seconds: 15);

  // ==========================================================================
  // 1. ฟังก์ชันดึงรายชื่อผู้ใช้ทั้งหมด (GET /api/admin/users)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
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
  // 2. ฟังก์ชันระงับ / ปลดระงับบัญชีผู้ใช้ (PATCH /api/admin/users/:id/status)
  // ==========================================================================
  Future<Map<String, dynamic>> updateUserStatus({
    required String token,
    required String userId,
    required bool isActive,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/$userId/status'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'is_active': isActive ? 1 : 0}),
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
  // 3. ฟังก์ชันยืนยันตัวตนผู้ขาย KYC (PATCH /api/admin/users/:id/verify)
  // ==========================================================================
  Future<Map<String, dynamic>> verifySeller({
    required String token,
    required String userId,
    required bool isVerified,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/$userId/verify'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'is_verified': isVerified ? 1 : 0}),
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
  // 4. ฟังก์ชันลบบัญชีผู้ใช้ (DELETE /api/admin/users/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> deleteUser({
    required String token,
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required.');
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users/$userId'),
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
        throw Exception(data['message'] ?? 'Unable to delete user');
      }
    } catch (e) {
      debugPrint('AdminController.deleteUser error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ฟังก์ชันอัปโหลดรูปภาพโปสเตอร์คอนเสิร์ต (POST /api/admin/concerts/upload-poster)
  // ==========================================================================
  Future<String> uploadConcertPoster({
    required String token,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/concerts/upload-poster'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'poster',
          fileBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (data['poster_url'] ?? '').toString();
      } else {
        throw Exception(data['message'] ?? 'Unable to upload poster image');
      }
    } catch (e) {
      debugPrint('AdminController.uploadConcertPoster error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 6. ฟังก์ชันดึงรายการคอนเสิร์ตทั้งหมด (GET /api/admin/concerts)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getAllConcerts(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/concerts'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else if (decoded is Map) {
          final list = decoded['concerts'] ?? decoded['data'] ?? [];
          if (list is List) {
            return list
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          }
        }
        return [];
      } else {
        final data = _safeDecodeMap(response.body);
        throw Exception(data['message'] ?? 'Unable to fetch concerts list');
      }
    } catch (e) {
      debugPrint('AdminController.getAllConcerts error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 7. ฟังก์ชันเพิ่มคอนเสิร์ตใหม่ (POST /api/admin/concerts)
  // ==========================================================================
  Future<Map<String, dynamic>> createConcert({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/concerts'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to create concert');
      }
    } catch (e) {
      debugPrint('AdminController.createConcert error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 8. ฟังก์ชันแก้ไขข้อมูลคอนเสิร์ต (PUT /api/admin/concerts/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> updateConcert({
    required String token,
    required String concertId,
    required Map<String, dynamic> payload,
  }) async {
    if (concertId.trim().isEmpty) {
      throw Exception('Concert ID is required.');
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/concerts/$concertId'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final data = _safeDecodeMap(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Unable to update concert');
      }
    } catch (e) {
      debugPrint('AdminController.updateConcert error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 9. ฟังก์ชันลบคอนเสิร์ต (DELETE /api/admin/concerts/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> deleteConcert({
    required String token,
    required String concertId,
  }) async {
    if (concertId.trim().isEmpty) {
      throw Exception('Concert ID is required.');
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/concerts/$concertId'),
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
        throw Exception(data['message'] ?? 'Unable to delete concert');
      }
    } catch (e) {
      debugPrint('AdminController.deleteConcert error: $e');
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