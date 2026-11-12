import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConcertController {
  ConcertController({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseUrl = 'http://localhost:3000/api/concerts';
  static const Duration _timeout = Duration(seconds: 15);

  // ==========================================================================
  // 1. ดึงรายการคอนเสิร์ตทั้งหมด พร้อมรองรับคำค้นหา (search) และหมวดหมู่ (category)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getConcerts({
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (category != null &&
          category.trim().isNotEmpty &&
          category.trim().toLowerCase() != 'all') {
        queryParams['category'] = category.trim();
      }

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await _client
          .get(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = body is List ? body : (body['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to retrieve concert information.');
      }
    } catch (e) {
      debugPrint('ConcertController.getConcerts error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 2. ดึงรายละเอียดคอนเสิร์ตตาม ID (GET /api/concerts/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> getConcertById(int concertId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/$concertId'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else if (response.statusCode == 404) {
        throw Exception('Concert not found');
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(
          msg ?? 'An error occurred while fetching concert details',
        );
      }
    } catch (e) {
      debugPrint('ConcertController.getConcertById error: $e');
      throw Exception(_cleanErrorMessage(e));
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
