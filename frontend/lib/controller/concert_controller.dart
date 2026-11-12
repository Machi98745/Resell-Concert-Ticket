import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConcertController {
  static const String baseUrl = 'http://localhost:3000/api/concerts';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client client;

  ConcertController({http.Client? client}) : client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> getConcerts({
    String? search,
    String? category,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (category != null &&
          category.trim().isNotEmpty &&
          category.trim().toLowerCase() != 'all') {
        queryParams['category'] = category.trim();
      }

      final Uri uri = Uri.parse(baseUrl).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await client
          .get(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(_timeout);

      final dynamic body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body is List) {
          return body.cast<Map<String, dynamic>>();
        } else if (body is Map && body.containsKey('data') && body['data'] is List) {
          return (body['data'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        final dynamic msg = body is Map ? body['message'] : null;
        throw Exception(msg?.toString() ?? 'Unable to retrieve concert information.');
      }
    } catch (e) {
      debugPrint('ConcertController.getConcerts error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getConcertById(int concertId) async {
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/$concertId'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(_timeout);

      final dynamic body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(body as Map);
      } else if (response.statusCode == 404) {
        throw Exception('Concert not found');
      } else {
        final dynamic msg = body is Map ? body['message'] : null;
        throw Exception(msg?.toString() ?? 'An error occurred while fetching concert details');
      }
    } catch (e) {
      debugPrint('ConcertController.getConcertById error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
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
