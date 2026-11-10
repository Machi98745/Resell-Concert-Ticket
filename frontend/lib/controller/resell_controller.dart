import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ResellController {
  // ใช้ localhost:3000 สำหรับ Web / Windows Desktop (หากรันบน Android Emulator เปลี่ยนเป็น 10.0.2.2:3000)
  static const String baseUrl = 'http://localhost:3000/api';

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

    // ป้องกันการตั้งราคาสูงเกินเพดานผิดปกติ (เช่น เกิน 1,000,000 บาท)
    if (parsedPrice > 1000000) {
      return 'The selling price is too high';
    }

    return null; // ผ่านการตรวจสอบ
  }

  // ==========================================================================
  // 2. ดึงรายการบัตรมือสองทั้งหมดที่สถานะเป็น available (GET /api/resell/listings)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getResellListings({int? concertId}) async {
    try {
      final uri = concertId != null
          ? Uri.parse('$baseUrl/resell/listings?concert_id=$concertId')
          : Uri.parse('$baseUrl/resell/listings');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = body is List ? body : (body['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(body['message'] ?? 'Unable to fetch resale listings');
      }
    } catch (e) {
      debugPrint('ResellController.getResellListings error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 3. ดึงรายละเอียดบัตรมือสองรายใบ (GET /api/resell/listings/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> getResellListingById(int listingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resell/listings/$listingId'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body is Map<String, dynamic> && body.containsKey('data')
            ? Map<String, dynamic>.from(body['data'])
            : Map<String, dynamic>.from(body);
      } else {
        throw Exception(body['message'] ?? 'Unable to find the resale listing');
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
      final response = await http.get(
        Uri.parse('$baseUrl/user/my-tickets'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = body is List ? body : (body['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception(body['message'] ?? 'Unable to fetch your tickets.');
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
    int? sellerId,
  }) async {
    // ตรวจสอบ Business Logic ก่อนยิง API
    final validationError = validateResellInput(
      ticketId: ticketId,
      priceText: resellPrice.toString(),
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resell/create'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ticket_id': ticketId,
          'resell_price': resellPrice,
          if (sellerId != null) 'seller_id': sellerId,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else {
        throw Exception(body['message'] ?? 'Unable to list ticket for resale');
      }
    } catch (e) {
      debugPrint('ResellController.createResellListing error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ฟังก์ชันช่วยจัดการข้อความ Error ให้สะอาดพร้อมแสดงบน UI
  String _cleanErrorMessage(Object error) {
    final msg = error.toString().replaceAll('Exception: ', '').trim();
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('ClientException')) {
      return 'Unable to connect to the server. Please check the Backend service.';
    }
    return msg;
  }
}