import 'package:flutter/foundation.dart';
import 'package:frontend/server/api_service.dart';

class PaymentController {
  static const List<String> allowedDeliveryMethods = [
    'delivery',
    'meetup',
    'Parcel Shipping',
    'Digital Transfer',
  ];

  // ==========================================================================
  // 1. Business Logic: ตรวจสอบข้อมูลการชำระเงินและที่อยู่/อีเมลจัดส่ง
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
      return (deliveryMethod == 'meetup' ||
              deliveryMethod == 'Digital Transfer')
          ? 'Please specify the location/time or email for ticket pickup'
          : 'Please enter the shipping address for ticket delivery';
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
  // 3. สร้างรายการจองและรอชำระเงิน 15 นาที (POST /api/payments/create)
  // ==========================================================================
  Future<Map<String, dynamic>> checkout({
    String? token,
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
      return await ApiService.createPayment({
        'listing_id': listingId,
        'payment_method': paymentMethod.trim(),
        'delivery_method': deliveryMethod,
        'shipping_info': shippingInfo.trim(),
        'receive_method': deliveryMethod,
        'receive_details': shippingInfo.trim(),
      });
    } catch (e) {
      debugPrint('PaymentController.checkout error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 4. ยืนยันการชำระเงินภายใน 15 นาที + โอนสิทธิ์ตั๋ว (POST /api/payments/:id/confirm)
  // ==========================================================================
  Future<Map<String, dynamic>> confirmPayment({
    String? token,
    required int paymentId,
  }) async {
    if (paymentId <= 0) {
      throw Exception('Invalid payment ID');
    }

    try {
      final res = await ApiService.confirmPayment(paymentId);
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'status': 'completed', 'payment_id': paymentId};
    } catch (e) {
      debugPrint('PaymentController.confirmPayment error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ยกเลิกรายการสั่งซื้อที่ยังไม่ชำระเงิน (POST /api/payments/:id/cancel)
  // ==========================================================================
  Future<Map<String, dynamic>> cancelPayment({
    required int paymentId,
  }) async {
    try {
      final res = await ApiService.cancelPayment(paymentId);
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'status': 'cancelled', 'payment_id': paymentId};
    } catch (e) {
      debugPrint('PaymentController.cancelPayment error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 6. ดึงประวัติคำสั่งซื้อของฉัน (GET /api/payments/my-orders)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      return await ApiService.getMyOrders();
    } catch (e) {
      debugPrint('PaymentController.getMyOrders error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 7. เช็กสถานะคำสั่งซื้อตาม ID (GET /api/payments/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> getPaymentById({
    required int paymentId,
  }) async {
    try {
      final res = await ApiService.get('/payments/$paymentId');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      throw Exception('Invalid payment detail');
    } catch (e) {
      debugPrint('PaymentController.getPaymentById error: $e');
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