import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uth_room_booking/main.dart';
import 'package:uth_room_booking/theme/app_theme.dart';
import 'package:uth_room_booking/features/splash/presentation/splash_screen.dart';
import 'package:uth_room_booking/homepage.dart';

// TODO: sửa đường dẫn này cho đúng vị trí file login_page.dart của bạn.
import 'package:uth_room_booking/features/auth/login_page.dart';

/// Màn hình điện thoại giả lập, đủ cao để không phải cuộn trong test.
Future<void> _useMobileScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Gỡ toàn bộ widget để dispose AnimationController / Timer còn sót.
Future<void> _unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

/// Bọc LoginPage trong MaterialApp có theme thật của app.
Widget _loginApp() =>
    MaterialApp(theme: AppTheme.light, home: const LoginPage());

void main() {
  // QUY TẮC: màn hình có animation lặp (splash, ảnh trôi ở trang đăng nhập)
  // thì KHÔNG dùng pumpAndSettle(). Dùng pump(Duration) thay thế.

  group('Splash', () {
    testWidgets('application starts on the splash screen', (tester) async {
      await _useMobileScreen(tester);

      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      // Đẩy thời gian qua để các Timer/Future.delayed của splash chạy xong,
      // tránh lỗi "A Timer is still pending" khi test kết thúc.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));

      await _unmountApp(tester);
    });
  });

  group('LoginPage', () {
    testWidgets('hiển thị tab, form và mặc định là Sinh viên', (tester) async {
      await _useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      // 'Sinh viên' xuất hiện ở tab và ở tiêu đề form.
      expect(find.text('Sinh viên'), findsNWidgets(2));
      expect(find.text('Giảng viên'), findsOneWidget); // chỉ ở tab
      expect(find.text('Mã sinh viên'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);

      await _unmountApp(tester);
    });

    testWidgets('bấm tab Giảng viên thì đổi nhãn và tiêu đề', (tester) async {
      await _useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.tap(find.text('Giảng viên'));
      // Chờ AnimatedSwitcher (450ms) chạy xong.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Giảng viên'), findsNWidgets(2)); // tab + tiêu đề
      expect(find.text('Mã giáo viên'), findsOneWidget);
      expect(find.text('Mã sinh viên'), findsNothing);

      await _unmountApp(tester);
    });

    testWidgets('để trống rồi đăng nhập thì báo lỗi', (tester) async {
      await _useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      expect(find.text('Vui lòng nhập mã sinh viên'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      await _unmountApp(tester);
    });

    testWidgets('nhập đủ thông tin thì vào HomePage (demo)', (tester) async {
      await _useMobileScreen(tester);

      await tester.pumpWidget(_loginApp());
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), '2251120001');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));

      // Chờ hiệu ứng chuyển trang.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);

      await _unmountApp(tester);
    });
  });
}
