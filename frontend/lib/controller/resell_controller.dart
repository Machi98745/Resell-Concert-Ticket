import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ResellController {
  static const String baseUrl = 'http://localhost:3000/api';
  static const double maxResellPrice = 1000000;
  static const Duration _timeout = Duration(seconds: 15);

  // ==========================================================================
  // 1. Business Logic: ตรวจสอบความถูกต้องของราคาฝากขาย (Validation)
  // ==========================================================================
  static String? validateResellInput({
    required int? ticketId,
    required String priceText,
    double? originalPrice,
  }) {
    if (ticketId == null || ticketId <= 0) {
      return 'Please select a concert ticket to list for resale';
    }

    final parsedPrice = double.tryParse(priceText.trim());
    if (parsedPrice == null) {
      return 'Please enter a valid selling price';
    }

    if (parsedPrice <= 0) {
      return 'The selling price must be greater than 0 THB';
    }

    if (parsedPrice > maxResellPrice) {
      return 'The selling price is too high';
    }

    if (originalPrice != null &&
        originalPrice > 0 &&
        parsedPrice > originalPrice * 5) {
      return 'The selling price exceeds the maximum allowed markup';
    }

    return null;
  }

  // ==========================================================================
  // 2. ดึงรายการบัตรมือสองทั้งหมดที่สถานะเป็น available (GET /api/resell/listings)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getResellListings({
    int? concertId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (concertId != null) {
        queryParams['concert_id'] = concertId.toString();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/resell/listings').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http
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
        throw Exception(msg ?? 'Unable to fetch resale listings');
      }
    } catch (e) {
      debugPrint('ResellController.getResellListings error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 3. ดึงรายละเอียดบัตรมือสองรายใบ (GET /api/resell/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> getResellListingById(int listingId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/resell/$listingId'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body is Map<String, dynamic> && body.containsKey('data')
            ? Map<String, dynamic>.from(body['data'])
            : Map<String, dynamic>.from(body);
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to find the resale listing');
      }
    } catch (e) {
      debugPrint('ResellController.getResellListingById error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 4. ดึงบัตรของผู้ใช้ที่ล็อกอินอยู่เพื่อแสดงใน Dropdown หน้า Sell (GET /api/user/my-tickets)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getMyTickets(String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Please log in to view your tickets');
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/my-tickets'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = body is List ? body : (body['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expired. Please log in again.');
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to fetch your tickets.');
      }
    } catch (e) {
      debugPrint('ResellController.getMyTickets error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ลงประกาศขายบัตรมือสอง (POST /api/resell/create)
  // ==========================================================================
  Future<Map<String, dynamic>> createResellListing({
    required String token,
    required int ticketId,
    required double resellPrice,
    double? originalPrice,
    String deliveryType = 'Parcel Shipping',
    String? shippingCompany,
    double shippingFee = 0.0,
    String? deliveryNote,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
  }) async {
    final validationError = validateResellInput(
      ticketId: ticketId,
      priceText: resellPrice.toString(),
      originalPrice: originalPrice,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    if (token.trim().isEmpty) {
      throw Exception('Please log in before listing a ticket for resale');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/resell/create'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'ticket_id': ticketId,
              'resell_price': resellPrice,
              'delivery_type': deliveryType,
              'shipping_company': shippingCompany,
              'shipping_fee': shippingFee,
              'delivery_note': deliveryNote,
              'bank_name': bankName,
              'bank_account_name': bankAccountName,
              'bank_account_number': bankAccountNumber,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to list ticket for resale');
      }
    } catch (e) {
      debugPrint('ResellController.createResellListing error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 6. ดึงรายการประกาศขายของตัวเอง (GET /api/resell/my-listings)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getMyResellListings(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/resell/my-listings'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = body is List ? body : (body['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to fetch your resale listings');
      }
    } catch (e) {
      debugPrint('ResellController.getMyResellListings error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 7. ยกเลิกประกาศขายตั๋วมือสอง (PATCH /api/resell/:id/cancel)
  // ==========================================================================
  Future<Map<String, dynamic>> cancelResellListing({
    required String token,
    required int listingId,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/resell/$listingId/cancel'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else {
        final msg = body is Map ? body['message'] : null;
        throw Exception(msg ?? 'Unable to cancel resale listing');
      }
    } catch (e) {
      debugPrint('ResellController.cancelResellListing error: $e');
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
