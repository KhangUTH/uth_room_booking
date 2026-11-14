import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/technician/widgets/technician_task_card.dart';
import 'package:uth_room_booking/main.dart';
import 'package:uth_room_booking/theme/app_theme.dart';
import 'package:uth_room_booking/features/splash/presentation/splash_screen.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';
import 'package:uth_room_booking/features/auth/presentation/login_page.dart';

import 'support/widget_test_helpers.dart';

/// Bọc LoginPage trong MaterialApp có theme thật của app.
Widget _loginApp() => MaterialApp(
  theme: AppTheme.light,
  home: const LoginPage(),
  onGenerateRoute: AppRouter.onGenerateRoute,
);

void main() {
  group('Splash', () {
    testWidgets('application starts on the splash screen', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      // Đẩy thời gian qua để các Timer/Future.delayed của splash chạy xong,
      // tránh lỗi "A Timer is still pending" khi test kết thúc.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LoginPage), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('LoginPage', () {
    testWidgets('sinh viên xem lại báo cáo đang xử lý sau khi đổi tài khoản', (
      tester,
    ) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));

      Future<void> login(String id) async {
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(fields.evaluate().length - 2), id);
        await tester.enterText(fields.last, 'mat-khau-demo');
        final button = find.widgetWithText(ElevatedButton, 'Đăng nhập').last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> logout() async {
        await tester.tap(find.text('Cá nhân'));
        await tester.pumpAndSettle();
        final button = find.text('Đăng xuất');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      await login('21110234');
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng A101').last);
      await tester.pumpAndSettle();
      const title = 'Máy phòng A101 bị lỗi';
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, title);
      await tester.enterText(fields.at(1), 'Không mở được máy');
      final submit = find.text('Gửi báo cáo');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await logout();

      final technicianLogin = find.text('Cổng dành cho kỹ thuật viên');
      await tester.ensureVisible(technicianLogin);
      await tester.tap(technicianLogin);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await login('KT-0217');
      await tester.tap(find.text('Công việc'));
      await tester.pumpAndSettle();
      final card = find.widgetWithText(TechnicianTaskCard, title);
      await tester.ensureVisible(card);
      await tester.tap(
        find.descendant(of: card, matching: find.text('Nhận việc')),
      );
      await tester.pumpAndSettle();
      await logout();

      await login('21110234@ut.edu.vn');
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.text('Đang xử lý'), findsOneWidget);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text('Không mở được máy'), findsOneWidget);
      expect(find.textContaining('Đang xử lý lúc'), findsOneWidget);
    });

    testWidgets('đăng nhập và đăng xuất thay thế route hiện tại', (
      tester,
    ) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(_loginApp());
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '21110234');
      await tester.enterText(fields.at(1), 'mat-khau-demo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('MSSV: 21110234'), findsOneWidget);
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      final logout = find.text('Đăng xuất');
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
        isFalse,
      );
      await unmountApp(tester);
    });
    testWidgets('hiển thị tab, form và mặc định là Sinh viên', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      // 'Sinh viên' xuất hiện ở tab và ở tiêu đề form.
      expect(find.text('Sinh viên'), findsNWidgets(2));
      expect(find.text('Giảng viên'), findsOneWidget); // chỉ ở tab
      expect(find.text('Mã sinh viên'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('bấm tab Giảng viên thì đổi nhãn và tiêu đề', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.tap(find.text('Giảng viên'));
      // Chờ AnimatedSwitcher (450ms) chạy xong.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Giảng viên'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('Mã giáo viên'), findsOneWidget);
      expect(find.text('Mã sinh viên'), findsNothing);

      await unmountApp(tester);
    });

    testWidgets('để trống rồi đăng nhập thì báo lỗi', (tester) async {
      await useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      expect(find.text('Vui lòng nhập mã sinh viên'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);

      await unmountApp(tester);
    });
  });
}
