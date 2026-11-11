// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
// import 'package:frontend/views/payment_page.dart';

void main() {
  testWidgets('app opens the sell ticket page', (WidgetTester tester) async {
    await tester.pumpWidget(const ResellCertApp());

    expect(find.text('Sell Your Ticket'), findsOneWidget);
  });

  /* testWidgets('payment page can be previewed independently', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PaymentPage()));

    expect(find.text('Select Payment Method'), findsOneWidget);
  }); */
}
