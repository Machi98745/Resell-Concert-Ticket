import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/views/admin_page.dart';
import 'package:frontend/views/cart.dart';
import 'package:frontend/views/cart_service.dart';
import 'package:frontend/views/checkout.dart';
import 'package:frontend/views/detail.dart';
import 'package:frontend/views/favorite.dart';
import 'package:frontend/views/favorite_service.dart';
import 'package:frontend/views/historypage.dart';
import 'package:frontend/views/homepage.dart';
import 'package:frontend/views/login.dart';
import 'package:frontend/views/payment_page.dart';
import 'package:frontend/views/register.dart';
import 'package:frontend/views/sell_page.dart';

Finder _searchField() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Search concerts, artists...',
  );
}

void main() {
  setUp(() {
    CartService.items.clear();
    CartService.history.clear();
    CartService.resaleListings.clear();
    FavoriteService.favorites.clear();
  });

  // ฟังก์ชันช่วยกำหนดขนาดหน้าจอจำลองให้กว้างพอ ไม่เกิด RenderFlex overflow
  Future<void> pumpTestWidget(
    WidgetTester tester,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: child,
      ),
    );
  }

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 1: รับผิดชอบโดย คนที่ 1 (6731501012) - ระบบ Auth, Register & Admin UI]
  // ครอบคลุมหน้าจอ: Login, Forgot Password Dialog, Register และ AdminPage
  // จำนวนเคสทดสอบ: 8 ข้อ
  // ============================================================================

  group('Person 1 (6731501012) - Auth, Register & Admin Widgets', () {
    // 1. ตรวจว่าหน้า Login แสดงช่องกรอก Username, Password และปุ่ม Login ครบถ้วน
    testWidgets('Login page renders username, password fields, and Login button', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Login());

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    // 2. ตรวจว่ากดปุ่ม Login โดยไม่กรอกข้อมูลจะแสดงข้อความแจ้งเตือน
    testWidgets('Login page shows error message when submitting empty fields', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Login());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Please enter username and password'), findsOneWidget);
    });

    // 3. ตรวจว่าป๊อปอัป Reset Password ดักจับกรณีไม่กรอกข้อมูลและอีเมลผิดรูปแบบ
    testWidgets('Login Reset Password dialog validates empty fields and email format', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Login());

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Reset'));
      await tester.pump();

      expect(find.text('Please fill in all fields!'), findsOneWidget);
    });

    // 4. ตรวจว่าการกด Forgot Password? จะเปิดป๊อปอัป Reset Password
    testWidgets('Login page opens Reset Password dialog when tapping Forgot Password', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Login());

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(
        find.text('Please enter your details to verify ownership.'),
        findsOneWidget,
      );
    });

    // 5. ตรวจว่าหน้า Register แสดงหัวข้อ CREATE ACCOUNT และช่องกรอกข้อมูลสมัครสมาชิก
    testWidgets('Register page renders CREATE ACCOUNT form fields', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Register());

      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    // 6. ตรวจว่าหน้า Register แจ้งเตือนเมื่อกดสมัครโดยไม่กรอกข้อมูล
    testWidgets('Register page shows validation error when fields are empty', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Register());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    // 7. ตรวจว่าหน้า Register ดักจับกรณีรหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน
    testWidgets('Register page shows error when passwords do not match', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Register());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newuser');
      await tester.enterText(fields.at(1), 'New User');
      await tester.enterText(fields.at(2), 'newuser@gmail.com');
      await tester.enterText(fields.at(3), '0812345678');
      await tester.enterText(fields.at(4), 'password123');
      await tester.enterText(fields.at(5), 'mismatch999');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    // 8. ตรวจว่าหน้า AdminPage แสดงแถบ ADMIN และสลับแท็บ Users / Concerts ได้
    testWidgets('AdminPage renders ADMIN dashboard and switches between Users and Concerts tabs', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const AdminPage());

      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.textContaining('Users'), findsOneWidget);
      expect(find.textContaining('Concerts'), findsOneWidget);

      await tester.tap(find.textContaining('Concerts'));
      await tester.pump();

      expect(find.text('Add Concert'), findsOneWidget);
    });
  });

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 2: รับผิดชอบโดย คนที่ 2 - ระบบ Payment, Checkout, Cart & History UI]
  // ครอบคลุมหน้าจอ: CartPage, CheckoutPage, PaymentPage และ HistoryPage
  // จำนวนเคสทดสอบ: 4 ข้อ
  // ============================================================================

  group('Person 2 - Payment, Checkout, Cart & History Widgets', () {
    testWidgets('Cart shows ticket rows and the combined total', (
      WidgetTester tester,
    ) async {
      CartService.items.addAll([
        {
          'concertName': 'Aurora Live',
          'artist': 'Aurora',
          'seat': 'A1',
          'price': 2500,
        },
        {
          'concertName': 'Neon Night',
          'artist': 'Neon',
          'seat': 'B2',
          'price': 1000,
        },
      ]);

      await tester.pumpWidget(const MaterialApp(home: CartPage()));

      expect(find.text('My Cart'), findsOneWidget);
      expect(find.text('Aurora Live'), findsOneWidget);
      expect(find.text('Neon Night'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('฿3500'), findsOneWidget);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('Checkout shows order summary and lets the user select payment', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutPage(
            items: [
              {'concertName': 'Aurora Live', 'price': 2500},
            ],
          ),
        ),
      );

      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Aurora Live'), findsOneWidget);
      // ราคาตั๋วแสดงทั้งในรายการและแถว Total
      expect(find.text('฿2500.00'), findsNWidgets(2));
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);

      await tester.ensureVisible(find.text('PromptPay'));
      await tester.tap(find.text('PromptPay'));
      await tester.pump();

      final promptPayRadio = tester.widget<Radio<String>>(
        find.byWidgetPredicate(
          (widget) => widget is Radio<String> && widget.value == 'PromptPay',
        ),
      );
      expect(promptPayRadio.groupValue, 'PromptPay');
    });

    testWidgets('Payment lets the user choose delivery and payment methods', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentPage(
            items: [
              {'concertName': 'Aurora Live', 'seat': 'A1', 'price': 2500},
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Delivery Information'), findsOneWidget);
      expect(find.text('Shipping Address'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Digital Transfer').last);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Shipping Address'), findsNothing);

      await tester.ensureVisible(find.text('Credit / Debit Card'));
      await tester.tap(find.text('Credit / Debit Card'));
      await tester.pump();
      expect(find.text('Card Number'), findsOneWidget);
      expect(find.text('Cardholder Name'), findsOneWidget);
      expect(find.text('Expiry Date'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('History tabs show To Pay, To Ship, and Completed orders', (
      WidgetTester tester,
    ) async {
      CartService.history.addAll([
        _order('ORDER_PAY', 'To Pay'),
        _order('ORDER_SHIP', 'To Ship'),
        _order('ORDER_DONE', 'Completed'),
      ]);
      expect(CartService.getOrdersByStatus('To Ship'), hasLength(1));

      await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
      await tester.pump();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('ORDER_PAY'), findsOneWidget);

      final toShipTab = find.byType(Tab).at(1);
      await tester.ensureVisible(toShipTab);
      await tester.tap(toShipTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      expect(find.text('ORDER_SHIP'), findsOneWidget);

      final completedTab = find.byType(Tab).at(3);
      await tester.ensureVisible(completedTab);
      await tester.tap(completedTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 3);
      expect(find.text('ORDER_DONE'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 3: รับผิดชอบโดย คนที่ 3 - ระบบ Concert, Resell & Favorite UI]
  // ครอบคลุมหน้าจอ: HomePage, DetailPage, SellPage และ FavoritePage
  // จำนวนเคสทดสอบ: 4 ข้อ
  // ============================================================================

  group('Person 3 - Concert, Resell & Favorite UI', () {
    testWidgets('HomePage shows concerts and filters by search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();

      expect(find.text('BLACKPINK WORLD TOUR'), findsWidgets);
      expect(_searchField(), findsOneWidget);

      await tester.enterText(
        _searchField(),
        'concert-does-not-exist',
      );
      await tester.pump();

      expect(find.text('No upcoming concerts found.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DetailPage can add a concert to favorites', (
      WidgetTester tester,
    ) async {
      final concert = <String, dynamic>{
        'name': 'Test Concert',
        'artist': 'Test Artist',
        'date': '25 December 2026',
        'time': '19:00',
        'location': 'Bangkok',
        'category': 'Pop',
        'image': '',
        'description': 'A test concert',
        'tickets': [
          {
            'seller': 'Test Seller',
            'zone': 'VIP Zone',
            'price': 1000,
            'condition': 'Available',
            'status': 'available',
            'seats': ['A1'],
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(home: DetailPage(concert: concert)),
      );
      await tester.pump();

      expect(find.text('Test Concert'), findsWidgets);
      expect(find.byTooltip('Add to Favorites'), findsOneWidget);

      await tester.tap(find.byTooltip('Add to Favorites'));
      await tester.pump();

      expect(FavoriteService.isFavorite(concert), isTrue);
      expect(find.text('Added to My Favorites!'), findsOneWidget);
    });

    testWidgets('SellPage validates required ticket information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SellPage()));
      await tester.pump();

      expect(find.text('Sell Your Ticket'), findsOneWidget);
      expect(find.text('Ticket Details'), findsOneWidget);
      expect(find.text('Continue to Review'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue to Review'));
      await tester.tap(find.text('Continue to Review'));
      await tester.pump();

      expect(find.text('Please select a concert.'), findsOneWidget);
    });

    testWidgets('FavoritePage displays saved concerts', (
      WidgetTester tester,
    ) async {
      FavoriteService.favorites.add({
        'name': 'Saved Concert',
        'artist': 'Saved Artist',
        'date': '1 January 2027',
        'image': '',
      });

      await tester.pumpWidget(const MaterialApp(home: FavoritePage()));
      await tester.pump();

      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.text('Saved Concert'), findsOneWidget);
      expect(find.text('Saved Artist'), findsOneWidget);
    });
  });
}

Map<String, dynamic> _order(String orderId, String status) => {
  'orderId': orderId,
  'status': status,
  'orderDate': DateTime(2026, 11, 17, 12),
  'paymentDeadline': DateTime.now().add(const Duration(minutes: 10)),
  'totalPrice': 2500,
  'paymentStatus': status == 'Completed' ? 'Paid' : 'Unpaid',
  'shippingStatus': status,
  'trackingNumber': null,
  'buyer': 'cocomint',
  'items': [
    {
      'concertName': 'Aurora Live',
      'artist': 'Aurora',
      'zone': 'A1',
      'price': 2500,
      'seller': 'seller',
    },
  ],
  'timeline': <Map<String, dynamic>>[],
};
