import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/views/admin_page.dart';
import 'package:frontend/views/login.dart';
import 'package:frontend/views/register.dart';

void main() {
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

    // 3. ตรวจว่ากรอกรหัสผ่านผิดแล้วแสดงข้อความแจ้งเตือน Invalid username or password
    testWidgets('Login page shows error message when credentials are invalid', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const Login());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'cocomint');
      await tester.enterText(fields.at(1), 'wrongpass');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Invalid username or password'), findsOneWidget);
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

    // 8. ตรวจว่าหน้า AdminPage แสดงตาราง User Management และค้นหาชื่อผู้ใช้ได้
    testWidgets('AdminPage renders User Management dashboard and filters users by search', (
      WidgetTester tester,
    ) async {
      await pumpTestWidget(tester, const AdminPage());

      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('PinkSeller'), findsOneWidget);
      expect(find.text('Scammer101'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Pink');
      await tester.pump();

      expect(find.text('PinkSeller'), findsOneWidget);
      expect(find.text('Scammer101'), findsNothing);
    });
  });

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 2: รับผิดชอบโดย คนที่ 2 - ระบบ Payment, Checkout, Cart & History UI]
  // (เว้นไว้ให้คนที่ 2 เขียนและ Push เพิ่มเข้ามา)
  // ============================================================================

  // ============================================================================
  // 🧑‍💻 [ส่วนที่ 3: รับผิดชอบโดย คนที่ 3 - ระบบ Concert, Resell & Favorite UI]
  // (เว้นไว้ให้คนที่ 3 เขียนและ Push เพิ่มเข้ามา)
  // ============================================================================
}
