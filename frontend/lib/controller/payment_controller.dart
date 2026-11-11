import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentController {
  static const String baseUrl = 'http://localhost:3000/api/payments';
  static const List<String> allowedDeliveryMethods = [
    'delivery',
    'meetup',
    'Parcel Shipping',
    'Digital Transfer',
  ];

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

    if (!allowedDeliveryMethods.contains(deliveryMethod)) {
      return 'Invalid ticket pickup method';
    }

    if (shippingInfo.trim().isEmpty) {
      return deliveryMethod == 'meetup'
          ? 'Please specify the location and time for ticket pickup'
          : 'Please enter the address or email for ticket delivery';
    }

    return null;
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
    required String deliveryMethod,
    required String shippingInfo,
  }) async {
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
        throw Exception(body['message'] ?? 'Unable to confirm payment');
      }
    } catch (e) {
      debugPrint('PaymentController.confirmPayment error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ยกเลิกรายการสั่งซื้อที่ยังไม่ชำระเงิน (POST /api/payments/:id/cancel)
  // ==========================================================================
  Future<Map<String, dynamic>> cancelPayment({
    required String token,
    required int paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$paymentId/cancel'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(body);
      } else {
        throw Exception(body['message'] ?? 'Unable to cancel order');
      }
    } catch (e) {
      debugPrint('PaymentController.cancelPayment error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 6. ดึงประวัติคำสั่งซื้อของฉัน (GET /api/payments/my-orders)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getMyOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-orders'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = body is List ? body : (body['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(body['message'] ?? 'Unable to fetch orders');
      }
    } catch (e) {
      debugPrint('PaymentController.getMyOrders error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  String _cleanErrorMessage(Object error) {
    final msg = error.toString().replaceAll('Exception: ', '').trim();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('ClientException')) {
      return 'Unable to connect to the server. Please check the Backend service.';
    }
    return msg;
  }
}