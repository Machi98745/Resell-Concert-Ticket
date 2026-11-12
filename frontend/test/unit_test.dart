import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/concert_controller.dart';
import 'package:frontend/controller/login_controller.dart';
import 'package:frontend/controller/payment_controller.dart';
import 'package:frontend/controller/resell_controller.dart';
import 'package:frontend/views/cart_service.dart';
import 'package:frontend/views/favorite_service.dart';

void main() {
  // ตัวช่วยตรวจว่าฟังก์ชัน async โยน error พร้อมข้อความที่คาดหวัง
  Future<void> expectExceptionMessage(
    Future<dynamic> future,
    String message,
  ) async {
    await expectLater(
      future,
      throwsA(
        predicate((error) => error.toString().contains(message)),
      ),
    );
  }

  // ล้างข้อมูลแบบ static ก่อนเริ่มแต่ละ test เพื่อไม่ให้ข้อมูลปนกัน
  setUp(() {
    CartService.items.clear();
    CartService.history.clear();
    CartService.resaleListings.clear();
    FavoriteService.favorites.clear();
  });

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 1: รับผิดชอบโดย คนที่ 1 (6731501012) - ระบบ Auth & Login]
  // ครอบคลุม: การตรวจสอบสิทธิ์, Login Form, Token, Session, และ Input Validation
  // จำนวนเคสทดสอบ: 11 ข้อ (LoginController 6 ข้อ + AuthController 5 ข้อ)
  // ============================================================================

  group('LoginController', () {
    // ตรวจว่าล็อกอินด้วยบัญชีที่ถูกต้องได้ และตัดช่องว่างหัวท้าย
    test('accepts valid user credentials and trims surrounding spaces', () {
      final controller = LoginController();

      expect(controller.validateCredentials(' cocomint ', ' 2222 '), isNull);
    });

    // ตรวจว่าต้องกรอกทั้งชื่อผู้ใช้และรหัสผ่าน
    test('requires both username and password', () {
      final controller = LoginController();

      expect(
        controller.validateCredentials('   ', '1111'),
        'Please enter username and password',
      );
      expect(
        controller.validateCredentials('admin', '  '),
        'Please enter username and password',
      );
    });

    // ตรวจว่าปฏิเสธชื่อผู้ใช้ที่ไม่มีอยู่และรหัสผ่านที่ไม่ตรง
    test('rejects unknown users and incorrect passwords', () {
      final controller = LoginController();

      expect(
        controller.validateCredentials('unknown', '1111'),
        'Invalid username or password',
      );
      expect(
        controller.validateCredentials('admin', 'wrong'),
        'Invalid username or password',
      );
    });

    // ตรวจว่าระบุบัญชีผู้ดูแลระบบได้ถูกต้อง
    test('identifies the admin account', () {
      final controller = LoginController();

      expect(controller.isAdmin('admin'), isTrue);
      expect(controller.isAdmin('cocomint'), isFalse);
    });

    // ตรวจว่ากู้คืนรหัสผ่านได้เมื่ออีเมลและเบอร์โทรตรงกับบัญชี
    test('resets a password for a matching email and phone', () {
      final controller = LoginController();
      final username = controller.findUsernameByEmailAndPhone(
        ' admin@gmail.com ',
        '0812345678',
      );

      expect(username, 'admin');
      expect(controller.updatePassword(username!, 'newpass'), isTrue);
      expect(controller.validateCredentials('admin', 'newpass'), isNull);
      expect(
        controller.validateCredentials('admin', '1111'),
        'Invalid username or password',
      );
    });

    // ตรวจว่ารายละเอียดกู้คืนที่ไม่ตรงจะไม่พบบัญชี
    test('returns no account when recovery details do not match', () {
      final controller = LoginController();

      expect(
        controller.findUsernameByEmailAndPhone(
          'wrong@example.com',
          '0812345678',
        ),
        isNull,
      );
    });
  });

  group('AuthController input validation', () {
    final controller = AuthController();

    // ตรวจว่าการเข้าสู่ระบบต้องมีชื่อผู้ใช้และรหัสผ่าน
    test('login requires username and password', () async {
      await expectExceptionMessage(
        controller.login(' ', 'password'),
        'Please enter your username and password.',
      );
      await expectExceptionMessage(
        controller.login('username', ''),
        'Please enter your username and password.',
      );
    });

    // ตรวจว่าการสมัครต้องกรอกข้อมูลจำเป็นและรหัสผ่านอย่างน้อย 6 ตัว
    test('register requires fields and a six-character password', () async {
      await expectExceptionMessage(
        controller.register(
          fullName: '',
          username: 'user',
          email: 'user@example.com',
          password: '123456',
        ),
        'Please fill in all required fields.',
      );
      await expectExceptionMessage(
        controller.register(
          fullName: 'User',
          username: 'user',
          email: 'user@example.com',
          password: '12345',
        ),
        'Password must be at least 6 characters long.',
      );
    });

    // ตรวจว่าการแก้โปรไฟล์ต้องระบุชื่อและอีเมล
    test('profile update requires a name and email', () async {
      await expectExceptionMessage(
        controller.updateProfile(
          token: 'token',
          fullName: ' ',
          email: 'user@example.com',
        ),
        'Full name and email are required.',
      );
      await expectExceptionMessage(
        controller.updateProfile(token: 'token', fullName: 'User', email: ' '),
        'Full name and email are required.',
      );
    });

    // ตรวจว่าการเปลี่ยนรหัสผ่านต้องมีรหัสเดิมและรหัสใหม่ยาวอย่างน้อย 6 ตัว
    test('password changes require both values and a six-character new password', () async {
      await expectExceptionMessage(
        controller.changePassword(
          token: 'token',
          currentPassword: '',
          newPassword: 'newpass',
        ),
        'Please provide both current and new password.',
      );
      await expectExceptionMessage(
        controller.changePassword(
          token: 'token',
          currentPassword: 'oldpass',
          newPassword: '12345',
        ),
        'New password must be at least 6 characters long.',
      );
    });

    // ตรวจว่าการรีเซ็ตรหัสผ่านต้องมีอีเมล เบอร์โทร และรหัสใหม่ยาวอย่างน้อย 6 ตัว
    test('password reset requires contact details and a six-character password', () async {
      await expectExceptionMessage(
        controller.resetPassword(email: '', phone: '1234567890', newPassword: 'newpass'),
        'Please provide email, phone number, and new password.',
      );
      await expectExceptionMessage(
        controller.resetPassword(
          email: 'user@example.com',
          phone: '1234567890',
          newPassword: '12345',
        ),
        'New password must be at least 6 characters long.',
      );
    });
  });

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 2: รับผิดชอบโดย คนที่ 2 - ระบบ Payment & Order Checkout]
  // ครอบคลุม: การตรวจสอบข้อมูลสั่งซื้อ (Checkout), การล็อกเวลา 15 นาที (Expiry), และวงจรการชำระเงิน (Order Lifecycle)
  // จำนวนเคสทดสอบ: 16 ข้อ (Payment Checkout 6 ข้อ + Payment Expiry 5 ข้อ + Order Payment Lifecycle 5 ข้อ)
  // ============================================================================

  group('PaymentController.validateCheckoutInput', () {
    String? validate({
      int? listingId = 10,
      String paymentMethod = 'Bank Transfer',
      String deliveryMethod = 'Parcel Shipping',
      String shippingInfo = '12 Main Street',
    }) =>
        PaymentController.validateCheckoutInput(
          listingId: listingId,
          paymentMethod: paymentMethod,
          deliveryMethod: deliveryMethod,
          shippingInfo: shippingInfo,
        );

    // ตรวจว่ารายละเอียด checkout ที่ครบถ้วนผ่าน validation
    test('accepts complete checkout details', () {
      expect(validate(), isNull);
    });

    // ตรวจว่าต้องมี listing id ที่เป็นจำนวนบวก
    test('requires a valid listing id', () {
      expect(validate(listingId: null), 'Unable to find the requested ticket listing');
      expect(validate(listingId: 0), 'Unable to find the requested ticket listing');
    });

    // ตรวจว่าต้องเลือกวิธีชำระเงิน
    test('requires a payment method', () {
      expect(validate(paymentMethod: '  '), 'Please select a payment method');
    });

    // ตรวจว่าปฏิเสธวิธีรับตั๋วที่ระบบไม่รองรับ
    test('rejects unsupported delivery methods', () {
      expect(validate(deliveryMethod: 'Teleportation'), 'Invalid ticket pickup method');
    });

    // ตรวจว่าการส่งพัสดุต้องมีที่อยู่จัดส่ง
    test('asks for delivery address when parcel shipping info is blank', () {
      expect(
        validate(shippingInfo: '  '),
        'Please enter the shipping address for ticket delivery',
      );
    });

    // ตรวจว่า meetup และ digital transfer ต้องมีรายละเอียดนัดรับ/อีเมล
    test('asks for pickup details for meetup or digital transfer', () {
      for (final method in ['meetup', 'Digital Transfer']) {
        expect(
          validate(deliveryMethod: method, shippingInfo: ''),
          'Please specify the location/time or email for ticket pickup',
        );
      }
    });
  });

  group('PaymentController payment expiry helpers', () {
    // ตรวจว่าค่าว่างหรือวันเวลาที่อ่านไม่ได้มีเวลาคงเหลือเป็นศูนย์
    test('returns zero for missing and invalid expiry values', () {
      expect(PaymentController.getRemainingSeconds(null), 0);
      expect(PaymentController.getRemainingSeconds('not a date'), 0);
      expect(PaymentController.isPaymentExpired(null), isTrue);
    });

    // ตรวจว่าเวลาที่หมดอายุแล้วถูกลดเหลือศูนย์และถือว่าหมดอายุ
    test('clamps expired timestamps to zero', () {
      final expired = DateTime.now().subtract(const Duration(minutes: 1));
      expect(PaymentController.getRemainingSeconds(expired.toIso8601String()), 0);
      expect(PaymentController.isPaymentExpired(expired.toIso8601String()), isTrue);
    });

    // ตรวจว่าเวลาหมดอายุในอนาคตยังเหลือเวลาและยังไม่หมดอายุ
    test('reports a future payment as not expired', () {
      final future = DateTime.now().add(const Duration(minutes: 5));
      expect(PaymentController.getRemainingSeconds(future.toIso8601String()), greaterThan(0));
      expect(PaymentController.isPaymentExpired(future.toIso8601String()), isFalse);
    });

    // ตรวจว่าปฏิเสธ checkout ที่ไม่มี listing ก่อนเรียก API
    test('rejects incomplete checkout before sending a request', () async {
      await expectExceptionMessage(
        PaymentController().checkout(
          token: 'token',
          listingId: 0,
          paymentMethod: 'Bank Transfer',
          deliveryMethod: 'Parcel Shipping',
          shippingInfo: 'Address',
        ),
        'Unable to find the requested ticket listing',
      );
    });

    // ตรวจว่าปฏิเสธ payment id ที่ไม่เป็นจำนวนบวกก่อนยืนยัน
    test('rejects a nonpositive payment id before confirming', () async {
      await expectExceptionMessage(
        PaymentController().confirmPayment(token: 'token', paymentId: 0),
        'Invalid payment ID',
      );
    });
  });

  group('CartService order checkout and payment lifecycle', () {
    // ตรวจการสร้างออเดอร์ unpaid คัดลอกรายการ และล้างตะกร้า
    test('creates an unpaid order, copies items, and clears the cart', () {
      final ticket = {'id': 2, 'price': '250'};
      CartService.addToCart(ticket);

      final order = CartService.createOrder();

      expect(order, isNotNull);
      expect(order!['status'], 'To Pay');
      expect(order['paymentStatus'], 'Unpaid');
      expect(order['totalPrice'], 250);
      expect(order['paymentDeadline'], isA<DateTime>());
      expect(CartService.items, isEmpty);
      expect(CartService.history, contains(order));
      expect(order['items'], isNot(same(CartService.items)));
    });

    // ตรวจว่าไม่สร้างออเดอร์เมื่อรายการสินค้าเป็นค่าว่าง
    test('does not create an order from an empty list', () {
      expect(CartService.createOrderFromItems([]), isNull);
    });

    // ตรวจว่าระบบยกเลิกออเดอร์ที่เลยกำหนดชำระเงิน
    test('expires unpaid orders after their payment deadline', () {
      final order = <String, dynamic>{
        'status': 'To Pay',
        'paymentDeadline': DateTime.now().subtract(const Duration(seconds: 1)),
      };
      CartService.history.add(order);

      CartService.refreshExpiredOrders();

      expect(order['status'], 'Cancelled');
      expect(order['paymentStatus'], 'Expired');
      expect(CartService.hasActiveUnpaidOrder(), isFalse);
    });

    // ตรวจการเปลี่ยนสถานะออเดอร์ตั้งแต่จ่ายเงินจนยืนยันรับสินค้า
    test('advances order through payment, shipping, and receipt', () {
      final listing = <String, dynamic>{
        'listingId': 'LIST_1',
        'status': 'Available',
      };
      CartService.resaleListings.add(listing);
      final order = <String, dynamic>{
        'status': 'To Pay',
        'paymentDeadline': DateTime.now().add(const Duration(minutes: 5)),
        'items': [{'listingId': 'LIST_1'}],
        'timeline': <Map<String, dynamic>>[],
      };

      expect(CartService.payOrder(order), isTrue);
      expect(order['status'], 'To Ship');
      expect(listing['status'], 'Sold');
      expect(CartService.shipOrder(order), isTrue);
      expect(order['status'], 'To Receive');
      expect(order['trackingNumber'], startsWith('TP'));
      expect(listing['status'], 'Shipped');
      expect(CartService.confirmReceived(order), isTrue);
      expect(order['status'], 'Completed');
      expect(listing['status'], 'Completed');
    });

    // ตรวจว่าออเดอร์หมดอายุชำระไม่ได้และเปลี่ยนเป็นยกเลิก
    test('cannot pay an expired order', () {
      final order = <String, dynamic>{
        'status': 'To Pay',
        'paymentDeadline': DateTime.now().subtract(const Duration(seconds: 1)),
      };
      CartService.history.add(order);

      expect(CartService.payOrder(order), isFalse);
      expect(order['status'], 'Cancelled');
    });
  });

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 3: รับผิดชอบโดย คนที่ 3 - ระบบ Concert, Resell & Ticket Catalog]
  // ครอบคลุม: การค้นหาคอนเสิร์ต, ลงขายตั๋วต่อ (Resell Markup 5x), การเลือกตั๋วเข้าตะกร้า, และรายการโปรด
  // จำนวนเคสทดสอบ: 17 ข้อ (Resell 9 ข้อ + Ticket Selection 4 ข้อ + Concert 2 ข้อ + Favorite 2 ข้อ)
  // ============================================================================

  group('ResellController.validateResellInput', () {
    // ตรวจว่ารับ ticket และราคาขายต่อที่ถูกต้อง
    test('accepts a valid ticket and price', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '1500',
          originalPrice: 1000,
        ),
        isNull,
      );
    });

    // ตรวจว่าปฏิเสธ ticket id ที่หายไปหรือไม่เป็นจำนวนบวก
    test('rejects a missing or invalid ticket id', () {
      for (final ticketId in <int?>[null, 0, -1]) {
        expect(
          ResellController.validateResellInput(
            ticketId: ticketId,
            priceText: '1500',
          ),
          'Please select a concert ticket to list for resale',
        );
      }
    });

    // ตรวจว่าปฏิเสธราคาที่ไม่ใช่ตัวเลข ศูนย์ หรือติดลบ
    test('rejects invalid, zero, and negative prices', () {
      for (final price in ['abc', '0', '-1']) {
        expect(
          ResellController.validateResellInput(ticketId: 12, priceText: price),
          price == 'abc'
              ? 'Please enter a valid selling price'
              : 'The selling price must be greater than 0 THB',
        );
      }
    });

    // ตรวจเพดานราคาขายต่อสูงสุดที่ระบบกำหนด
    test('rejects prices above the global maximum', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '1000000.01',
        ),
        'The selling price is too high',
      );
    });

    // ตรวจว่าปฏิเสธราคาที่สูงเกิน 5 เท่าของราคาต้นทาง
    test('rejects markup above five times the original price', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '5001',
          originalPrice: 1000,
        ),
        'The selling price exceeds the maximum allowed markup',
      );
    });

    // ตรวจว่าราคาที่เท่ากับเพดาน 5 เท่ายังขายได้
    test('accepts the exact five-times markup boundary', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '5000',
          originalPrice: 1000,
        ),
        isNull,
      );
    });

    // ตรวจว่าต้องล็อกอินก่อนสร้างประกาศขาย
    test('requires a login token before creating a listing', () async {
      await expectExceptionMessage(
        ResellController().createResellListing(
          token: ' ',
          ticketId: 12,
          resellPrice: 1500,
        ),
        'Please log in before listing a ticket for resale',
      );
    });

    // ตรวจว่าข้อมูลประกาศที่ผิดถูกปฏิเสธก่อนเรียก API
    test('rejects invalid listing input before sending a request', () async {
      await expectExceptionMessage(
        ResellController().createResellListing(
          token: 'token',
          ticketId: 12,
          resellPrice: 0,
        ),
        'The selling price must be greater than 0 THB',
      );
    });

    // ตรวจว่าต้องล็อกอินก่อนโหลดตั๋วของผู้ใช้
    test('requires a token to load owned tickets', () async {
      await expectExceptionMessage(
        ResellController().getMyTickets('  '),
        'Please log in to view your tickets',
      );
    });
  });

  group('CartService ticket selection and cart items', () {
    // ตรวจว่าตั๋วที่ขายแล้วซื้อไม่ได้และเพิ่มลงตะกร้าไม่ได้
    test('detects sold tickets and prevents adding them to cart', () {
      final ticket = {'ticketId': 1, 'status': ' Sold '};
      expect(CartService.isTicketSold(ticket), isTrue);
      expect(CartService.canBuy(ticket), isFalse);
      expect(CartService.addToCart(ticket), isFalse);
      expect(CartService.items, isEmpty);
    });

    // ตรวจว่าเพิ่มตั๋วซ้ำไม่ได้และรวมราคาตั๋วในตะกร้าได้
    test('adds available tickets only once and totals prices', () {
      final first = {'ticketId': 1, 'price': '1200'};
      expect(CartService.addToCart(first), isTrue);
      expect(CartService.addToCart({'id': 1, 'price': '1200'}), isFalse);
      expect(CartService.addToCart({'id': 2, 'price': 800}), isTrue);
      expect(CartService.totalPrice, 2000);
    });

    // ตรวจว่าการลบด้วย index ที่ผิดไม่ทำให้ตะกร้าเสียหาย
    test('ignores invalid remove indexes', () {
      CartService.addToCart({'id': 1, 'price': 10});
      CartService.removeFromCart(-1);
      CartService.removeFromCart(1);
      expect(CartService.items, hasLength(1));
      CartService.removeFromCart(0);
      expect(CartService.items, isEmpty);
    });

    // ตรวจสถานะคอนเสิร์ตเมื่อไม่มีตั๋ว มีตั๋วขายได้ หรือขายหมด
    test('classifies sold out, available, and empty concerts', () {
      expect(CartService.getConcertStatus({'tickets': []}), 'No Tickets');
      expect(CartService.getConcertStatus({'tickets': [{'status': 'available'}]}), 'Available');
      expect(CartService.getConcertStatus({'tickets': [{'isSold': true}]}), 'Sold Out');
    });
  });

  group('ConcertController', () {
    // ตรวจการตัดช่องว่างคำค้น/หมวดหมู่และแปลงเป็น query parameters
    test('returns concerts and trims search filters into query parameters', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/concerts');
        expect(request.url.queryParameters, {'search': 'aurora', 'category': 'Pop'});
        return http.Response(jsonEncode([
          {'concert_id': 1, 'name': 'Aurora'}
        ]), 200);
      });

      final concerts = await ConcertController(client: client).getConcerts(
        search: ' aurora ',
        category: ' Pop ',
      );

      expect(concerts, hasLength(1));
      expect(concerts.single['name'], 'Aurora');
      client.close();
    });

    // ตรวจว่าเรียก endpoint ตาม concert id และแปลงข้อมูลตอบกลับได้
    test('returns a concert by id', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/concerts/7');
        return http.Response(jsonEncode({'concert_id': 7, 'name': 'Aurora'}), 200);
      });

      final concert = await ConcertController(client: client).getConcertById(7);

      expect(concert['concert_id'], 7);
      client.close();
    });
  });

  group('FavoriteService', () {
    final concert = {'name': 'Test Concert'};

    // ตรวจการกดเพิ่มและนำคอนเสิร์ตออกจากรายการโปรด
    test('toggles a concert into and out of favorites', () {
      expect(FavoriteService.isFavorite(concert), isFalse);
      FavoriteService.toggleFavorite(concert);
      expect(FavoriteService.isFavorite(concert), isTrue);
      FavoriteService.toggleFavorite(concert);
      expect(FavoriteService.isFavorite(concert), isFalse);
    });

    // ตรวจว่าลบคอนเสิร์ตออกจากรายการโปรดได้
    test('removes a favorited concert', () {
      FavoriteService.toggleFavorite(concert);
      FavoriteService.removeFavorite(concert);
      expect(FavoriteService.favorites, isEmpty);
    });
  });
}
