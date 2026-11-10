import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentController {
  static const String baseUrl = 'http://localhost:3000/api/payments';

  // ==========================================================================
  // 1. Business Logic: ตรวจสอบข้อมูลการชำระเงินและที่อยู่/สถานที่นัดรับ
  // ==========================================================================
  static String? validateCheckoutInput({
    required int? listingId,
    required String paymentMethod,
    required String deliveryMethod,
    required String shippingInfo,
  }) {
    if (listingId == null || listingId <= 0) {
      return 'Unable to find the requested ticket listing';
    }

    if (paymentMethod.trim().isEmpty) {
      return 'Please select a payment method';
    }

    if (deliveryMethod != 'delivery' && deliveryMethod != 'meetup') {
      return 'Invalid ticket pickup method (must be delivery or meetup)';
    }

    if (shippingInfo.trim().isEmpty) {
      return deliveryMethod == 'meetup'
          ? 'Please specify the location and time for ticket pickup'
          : 'Please enter the address for ticket delivery';
    }

    return null; // ผ่านการตรวจสอบ
  }

  // ==========================================================================
  // 2. Business Logic: คำนวณเวลาที่เหลือ (วินาที) จาก expires_at (15 นาที)
  // ==========================================================================
  static int getRemainingSeconds(String? expiresAtIso) {
    if (expiresAtIso == null || expiresAtIso.isEmpty) return 0;
    try {
      final expiresAt = DateTime.parse(expiresAtIso).toLocal();
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  static bool isPaymentExpired(String? expiresAtIso) {
    return getRemainingSeconds(expiresAtIso) <= 0;
  }

  // ==========================================================================
  // 3. สร้างรายการจองและรอชำระเงิน 15 นาที (POST /api/payments/checkout)
  // ==========================================================================
  Future<Map<String, dynamic>> checkout({
    required String token,
    required int listingId,
    required String paymentMethod,
    required String deliveryMethod, // 'delivery' หรือ 'meetup'
    required String shippingInfo,   // ที่อยู่จัดส่ง หรือ สถานที่นัดรับ
  }) async {
    // ตรวจสอบ Business Logic ก่อนยิง API
    final validationError = validateCheckoutInput(
      listingId: listingId,
      paymentMethod: paymentMethod,
      deliveryMethod: deliveryMethod,
      shippingInfo: shippingInfo,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkout'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'listing_id': listingId,
          'payment_method': paymentMethod,
          'delivery_method': deliveryMethod,
          'shipping_info': shippingInfo.trim(),
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else if (response.statusCode == 404) {
        throw Exception('This ticket listing has already been purchased or does not exist in the system');
      } else {
        throw Exception(body['message'] ?? 'Unable to create payment request');
      }
    } catch (e) {
      debugPrint('PaymentController.checkout error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 4. ยืนยันการชำระเงินภายใน 15 นาที + โอนสิทธิ์ตั๋ว (POST /api/payments/:id/confirm)
  // ==========================================================================
  Future<Map<String, dynamic>> confirmPayment({
    required String token,
    required int paymentId,
  }) async {
    if (paymentId <= 0) {
      throw Exception('Invalid payment ID');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$paymentId/confirm'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else {
        // กรณีเกิน 15 นาที Backend จะส่ง 400 พร้อมข้อความ Payment expired
        throw Exception(body['message'] ?? 'Unable to confirm payment');
      }
    } catch (e) {
      debugPrint('PaymentController.confirmPayment error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  String _cleanErrorMessage(Object error) {
    final msg = error.toString().replaceAll('Exception: ', '').trim();
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('ClientException')) {
      return 'Unable to connect to the server. Please check the Backend service.';
    }
    return msg;
  }
}