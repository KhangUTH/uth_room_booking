import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/features/auth/presentation/login_page.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_page.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

void main() {
  testWidgets('nhận phiếu từ trang chủ và xem trong lịch trên màn hình nhỏ', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TechnicianPage(name: 'Nguyễn Văn An', id: 'KTV01'),
      ),
    );
    expect(tester.takeException(), isNull);

    final receive = find.widgetWithText(ElevatedButton, 'Nhận việc').first;
    await tester.ensureVisible(receive);
    await tester.pumpAndSettle();
    await tester.tap(receive);
    await tester.pump();
    expect(find.text('Máy chiếu - H203'), findsNothing);

    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch công việc'), findsOneWidget);
    expect(find.text('Máy chiếu - H203'), findsOneWidget);
    expect(tester.takeException(), isNull);

    expect(find.text('Micro - H101'), findsOneWidget);
  });

  testWidgets('cổng kỹ thuật viên đăng nhập tới giao diện riêng', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginPage()),
    );
    final portal = find.text('Cổng dành cho kỹ thuật viên');
    await tester.ensureVisible(portal);
    await tester.tap(portal);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Mã kỹ thuật viên'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'KTV01');
    await tester.enterText(find.byType(TextFormField).last, 'demo');
    final login = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TechnicianPage), findsOneWidget);
    expect(find.text('Chờ nhận · 3 công việc'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
