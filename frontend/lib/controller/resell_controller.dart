import 'package:flutter/foundation.dart';
import 'package:frontend/server/api_service.dart';

class ResellController {
  static const double maxResellPrice = 1000000;

  // ==========================================================================
  // 1. Business Logic: ตรวจสอบความถูกต้องของเลขบัตรประชาชนไทย 13 หลัก
  // ==========================================================================
  static bool isValidThaiNationalId(String id) {
    final trimmed = id.trim();
    if (!RegExp(r'^\d{13}$').hasMatch(trimmed)) return false;

    final digits = trimmed.split('').map(int.parse).toList();
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (13 - i);
    }
    final checkDigit = (11 - (sum % 11)) % 10;
    return checkDigit == digits[12];
  }

  static String? validateSellerRegistration({
    required String fullName,
    required String nationalId,
    required bool acceptedTerms,
  }) {
    if (fullName.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (nationalId.trim().length != 13 || !isValidThaiNationalId(nationalId)) {
      return 'Please enter a valid 13-digit National ID';
    }
    if (!acceptedTerms) {
      return 'Please accept the terms and conditions';
    }
    return null;
  }

  // ==========================================================================
  // 2. Business Logic: ตรวจสอบข้อมูลบัตรและราคาฝากขาย (ไม่เกิน 5 เท่า)
  // ==========================================================================
  static String? validateResellInput({
    int? ticketId,
    String? priceText,
    double? originalPrice,
    int? concertId,
    String? ticketCode,
    String? zoneName,
    String? seatNumber,
    String? originalPriceText,
    String? sellingPriceText,
  }) {
    // โหมดตรวจสอบตาม ticketId (ใช้ใน Unit Test & โหมดเลือกตั๋วจากรายการ)
    if (priceText != null ||
        (concertId == null &&
            ticketCode == null &&
            zoneName == null &&
            seatNumber == null)) {
      if (ticketId == null || ticketId <= 0) {
        return 'Please select a concert ticket to list for resale';
      }

      final parsedPrice = double.tryParse((priceText ?? sellingPriceText ?? '').trim());
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

    if (concertId == null || concertId <= 0) {
      return 'Please select a concert.';
    }

    if (ticketCode == null || ticketCode.trim().isEmpty) {
      return 'Please enter your ticket code';
    }

    if (zoneName == null || zoneName.trim().isEmpty) {
      return 'Please enter the zone name';
    }

    if (seatNumber == null || seatNumber.trim().isEmpty) {
      return 'Please enter the seat number';
    }

    final parsedOriginal = double.tryParse((originalPriceText ?? '').trim());
    if (parsedOriginal == null || parsedOriginal <= 0) {
      return 'Please enter a valid original ticket price';
    }

    final parsedSelling = double.tryParse((sellingPriceText ?? '').trim());
    if (parsedSelling == null || parsedSelling <= 0) {
      return 'Please enter a valid selling price';
    }

    if (parsedSelling > maxResellPrice) {
      return 'The selling price is too high';
    }

    if (parsedSelling > parsedOriginal * 5) {
      return 'Selling price cannot exceed 5x the original price (Max: THB ${(parsedOriginal * 5).toStringAsFixed(0)})';
    }

    return null;
  }

  // ==========================================================================
  // 3. ตรวจสอบสถานะการยืนยันตัวตนผู้ขาย
  // ==========================================================================
  Future<Map<String, dynamic>> getSellerStatus() async {
    try {
      final statusRes = await ApiService.getSellerStatus();
      final rawStatus = (statusRes['status'] ?? 'not_submitted').toString();
      final verified = statusRes['is_verified'] == true ||
          statusRes['is_verified'] == 1 ||
          rawStatus == 'approved';

      return {
        ...statusRes,
        'status': verified ? 'approved' : rawStatus,
        'is_verified': verified,
      };
    } catch (_) {
      try {
        final profile = await ApiService.getProfile();
        final verified =
            profile['is_verified'] == 1 || profile['is_verified'] == true;
        return {
          'status': verified ? 'approved' : 'not_submitted',
          'is_verified': verified,
        };
      } catch (e) {
        debugPrint('ResellController.getSellerStatus error: $e');
        return {
          'status': 'not_submitted',
          'is_verified': false,
        };
      }
    }
  }

  // ==========================================================================
  // 4. ส่งข้อมูลลงทะเบียนยืนยันตัวตนผู้ขาย
  // ==========================================================================
  Future<Map<String, dynamic>> registerSeller({
    required String fullName,
    required String nationalId,
    required bool acceptedTerms,
  }) async {
    final validationError = validateSellerRegistration(
      fullName: fullName,
      nationalId: nationalId,
      acceptedTerms: acceptedTerms,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      return await ApiService.registerSeller({
        'full_name': fullName.trim(),
        'national_id': nationalId.trim(),
      });
    } catch (e) {
      debugPrint('ResellController.registerSeller error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 5. ดึงรายชื่อคอนเสิร์ตทั้งหมดในระบบ (GET /api/concerts)
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getConcerts() async {
    try {
      return await ApiService.getConcerts();
    } catch (e) {
      debugPrint('ResellController.getConcerts error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 6. ดึงรายการบัตรมือสองทั้งหมดที่สถานะเป็น available
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getResellListings({
    required int concertId,
  }) async {
    try {
      return await ApiService.getResellListings(concertId);
    } catch (e) {
      debugPrint('ResellController.getResellListings error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 7. ดึงบัตรของผู้ใช้ที่ล็อกอินอยู่
  // ==========================================================================
  Future<List<Map<String, dynamic>>> getMyTickets([String? token]) async {
    if (token != null && token.trim().isEmpty) {
      throw Exception('Please log in to view your tickets');
    }

    try {
      return await ApiService.getMyTickets();
    } catch (e) {
      debugPrint('ResellController.getMyTickets error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 8. ลงประกาศขายบัตรมือสอง (ส่งข้อมูลบัตร + คอนเสิร์ต ไปสร้างลง DB)
  // ==========================================================================
  Future<Map<String, dynamic>> createResellListing({
    String? token,
    int? ticketId,
    int? concertId,
    String? ticketCode,
    String? zoneName,
    String? seatNumber,
    double? originalPrice,
    required double resellPrice,
    String deliveryType = 'Parcel Shipping',
    String? shippingCompany,
    double shippingFee = 0.0,
    String? deliveryNote,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
  }) async {
    if (token != null && token.trim().isEmpty) {
      throw Exception('Please log in before listing a ticket for resale');
    }

    if (ticketId != null && concertId == null) {
      final validationError = validateResellInput(
        ticketId: ticketId,
        priceText: resellPrice.toString(),
        originalPrice: originalPrice,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }
    } else {
      final validationError = validateResellInput(
        concertId: concertId,
        ticketCode: ticketCode ?? '',
        zoneName: zoneName ?? '',
        seatNumber: seatNumber ?? '',
        originalPriceText: (originalPrice ?? 0).toString(),
        sellingPriceText: resellPrice.toString(),
      );
      if (validationError != null) {
        throw Exception(validationError);
      }
    }

    try {
      return await ApiService.createResellListing({
        if (ticketId != null) 'ticket_id': ticketId,
        if (concertId != null) 'concert_id': concertId,
        if (ticketCode != null) 'ticket_code': ticketCode.trim(),
        if (zoneName != null) 'zone_name': zoneName.trim(),
        if (seatNumber != null) 'seat_number': seatNumber.trim(),
        if (originalPrice != null) 'original_price': originalPrice,
        'resell_price': resellPrice,
        'delivery_type': deliveryType,
        'shipping_company': shippingCompany,
        'shipping_fee': shippingFee,
        'delivery_note': deliveryNote,
        'bank_name': bankName,
        'bank_account_name': bankAccountName,
        'bank_account_number': bankAccountNumber,
      });
    } catch (e) {
      debugPrint('ResellController.createResellListing error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 9. ดึงรายการประกาศขายของตัวเอง
  // ==========================================================================
  Future getMyResellListings() async {
    try {
      return await ApiService.getMyResellListings();
    } catch (e) {
      debugPrint('ResellController.getMyResellListings error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 10. ยกเลิกประกาศขายตั๋วมือสอง
  // ==========================================================================
  Future<Map<String, dynamic>> cancelResellListing({
    required int listingId,
  }) async {
    try {
      final data = await ApiService.patch('/resell/$listingId/cancel', {});
      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('ResellController.cancelResellListing error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 11. Business Logic: ตรวจสอบข้อมูลก่อนแก้ไขประกาศขาย
  // ==========================================================================
  static String? validateEditListing({
    required String zoneName,
    required String seatNumber,
    required String originalPriceText,
    required String sellingPriceText,
    required String shippingFeeText,
  }) {
    if (zoneName.trim().isEmpty) return 'Please enter the zone name.';
    if (seatNumber.trim().isEmpty) return 'Please enter the seat number.';

    final original = double.tryParse(originalPriceText.trim());
    if (original == null) return 'Please enter a valid original price.';
    if (original <= 0) return 'Original price must be greater than 0 THB.';
    if (original > maxResellPrice) {
      return 'Original price cannot exceed 1,000,000 THB.';
    }

    final selling = double.tryParse(sellingPriceText.trim());
    if (selling == null) return 'Please enter a valid selling price.';
    if (selling <= 0) return 'Selling price must be greater than 0 THB.';
    if (selling > maxResellPrice) {
      return 'Selling price cannot exceed 1,000,000 THB.';
    }
    if (selling > original * 5) {
      return 'Selling price cannot exceed 5x of original price.';
    }

    final fee = shippingFeeText.trim().isEmpty
        ? 0
        : double.tryParse(shippingFeeText.trim());
    if (fee == null) return 'Please enter a valid shipping fee.';
    if (fee < 0) return 'Shipping fee cannot be negative.';
    if (fee > maxResellPrice) return 'Shipping fee cannot exceed 1,000,000 THB.';

    return null;
  }

  // ==========================================================================
  // 12. แก้ไขประกาศขาย (PUT /api/resell/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> updateResellListing({
    required int listingId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await ApiService.updateResellListing(listingId, data);
    } catch (e) {
      debugPrint('ResellController.updateResellListing error: $e');
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ==========================================================================
  // 13. ลบประกาศขาย (DELETE /api/resell/:id)
  // ==========================================================================
  Future<Map<String, dynamic>> deleteResellListing({
    required int listingId,
  }) async {
    try {
      return await ApiService.deleteResellListing(listingId);
    } catch (e) {
      debugPrint('ResellController.deleteResellListing error: $e');
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