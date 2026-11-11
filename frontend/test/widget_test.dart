import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('app opens the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ResellCertApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
