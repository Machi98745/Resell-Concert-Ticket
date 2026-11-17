import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/views/cart.dart';
import 'package:frontend/views/cart_service.dart';
import 'package:frontend/views/checkout.dart';
import 'package:frontend/views/historypage.dart';
import 'package:frontend/views/payment_page.dart';

void main() {
  setUp(() {
    CartService.items.clear();
    CartService.history.clear();
    CartService.resaleListings.clear();
  });

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
