import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ==========================================
  // BASE URL
  // ==========================================

  // Chrome / Windows
  static const String baseUrl = 'http://localhost:3000/api';

  // Android Emulator:
  // หากรันบน Android Emulator ให้เปลี่ยนเป็น:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ==========================================
  // TOKEN (ใช้ FlutterSecureStorage ร่วมกับหน้า Login / Admin)
  // ==========================================
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ==========================================
  // HEADERS
  // ==========================================

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // RESPONSE HANDLER
  // ==========================================

  static dynamic _handleResponse(http.Response response) {
    dynamic data;

    try {
      data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      throw Exception('Invalid response from server: ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? data['message'] ?? 'Request failed'
          : response.body;

      throw Exception(message.toString());
    }

    return data;
  }

  // ==========================================
  // HTTP GET
  // ==========================================

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );

    return _handleResponse(response);
  }

  // ==========================================
  // HTTP POST
  // ==========================================

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ==========================================
  // HTTP PUT
  // ==========================================

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ==========================================
  // HTTP PATCH
  // ==========================================

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ==========================================
  // CONCERT API
  // ==========================================

  // GET /api/concerts
  static Future<List<Map<String, dynamic>>> getConcerts() async {
    // get() แปลง Response เป็น JSON แล้ว
    // ไม่ต้องเรียก _handleResponse() ซ้ำ

    final data = await get('/concerts');

    if (data is List) {
      return data.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    // รองรับกรณี Backend ส่ง Object มา 1 รายการ
    if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    }

    throw Exception('Invalid concert data');
  }

  // GET /api/concerts/:id
  static Future<Map<String, dynamic>> getConcertById(int id) async {
    final data = await get('/concerts/$id');

    if (data is! Map) {
      throw Exception('Invalid concert detail');
    }

    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // MY TICKETS API
  // ==========================================

  // GET /api/user/my-tickets
  static Future<List<Map<String, dynamic>>> getMyTickets() async {
    final data = await get('/user/my-tickets');

    if (data is! List) {
      throw Exception('Invalid my tickets data');
    }

    return data.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  // ==========================================
  // CREATE RESELL LISTING API
  // ==========================================

  // POST /api/resell/create
  static Future<Map<String, dynamic>> createResellListing(
    Map<String, dynamic> body,
  ) async {
    final data = await post('/resell/create', body);

    if (data is! Map) {
      throw Exception('Invalid resell listing response');
    }

    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // MY RESELL LISTINGS API
  // ==========================================

  // GET /api/resell/my-listings
  static Future<List<Map<String, dynamic>>> getMyResellListings() async {
    final data = await get('/resell/my-listings');

    if (data is! List) {
      throw Exception('Invalid my resell listings data');
    }

    return data.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }
  // ==========================================
  // RESELL LISTING API
  // ==========================================

  // GET /api/resell/listings?concert_id=:id
  static Future<List<Map<String, dynamic>>> getResellListings(
    int concertId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/resell/listings',
    ).replace(queryParameters: {'concert_id': concertId.toString()});

    final response = await http.get(uri, headers: await _authHeaders());

    final data = _handleResponse(response);

    if (data is! List) {
      throw Exception('Invalid resell listing data');
    }

    return data.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  // ==========================================
  // PROFILE API
  // ==========================================

  // GET /api/auth/me
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await get('/auth/me');

    if (data is! Map) {
      throw Exception('Invalid profile data');
    }

    return Map<String, dynamic>.from(data);
  }

  // PUT /api/auth/profile
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> body,
  ) async {
    final data = await put('/auth/profile', body);

    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user']);
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid updated profile data');
  }
  // ==========================================
  // SELLER REGISTRATION API
  // ==========================================

  // GET /api/resell/seller/status
  static Future<Map<String, dynamic>> getSellerStatus() async {
    final data = await get('/resell/seller/status');

    if (data is! Map) {
      throw Exception('Invalid seller status');
    }

    return Map<String, dynamic>.from(data);
  }

  // POST /api/resell/seller/register
  static Future<Map<String, dynamic>> registerSeller(
    Map<String, dynamic> body,
  ) async {
    final data = await post('/resell/seller/register', body);

    if (data is! Map) {
      throw Exception('Invalid seller registration response');
    }

    return Map<String, dynamic>.from(data);
  }
  // ==========================================
  // PAYMENT / HISTORY API
  // ==========================================

  // GET /api/payments/my-orders
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    final data = await get('/payments/my-orders');

    if (data is! List) {
      throw Exception('Invalid order history data');
    }

    return data.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  // POST /api/payments/create
  static Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> body,
  ) async {
    final data = await post('/payments/create', body);

    if (data is! Map) {
      throw Exception('Invalid payment response');
    }

    return Map<String, dynamic>.from(data);
  }

  // POST /api/payments/:id/confirm
  static Future<dynamic> confirmPayment(int paymentId) async {
    return post('/payments/$paymentId/confirm', {});
  }

  // POST /api/payments/:id/cancel
  static Future<dynamic> cancelPayment(int paymentId) async {
    return post('/payments/$paymentId/cancel', {});
  }
}
