import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/features/notifications/notifications.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_page.dart';
import 'package:uth_room_booking/shared/layouts/homepage.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

void main() {
  testWidgets('chuông và tùy chỉnh mở cùng danh sách, giữ trạng thái đã lưu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const HomePage(name: 'An', id: 'SV01'),
      ),
    );
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    await tester.tap(find.text('Xác nhận đặt phòng máy tính'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thông báo'));
    await tester.pumpAndSettle();
    Navigator.pop(tester.element(find.byType(BottomSheet)));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tùy chỉnh thông báo'));
    await tester.tap(find.text('Tùy chỉnh thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt phòng máy tính'), findsOneWidget);
    expect(find.text('Xác nhận sử dụng thiết bị'), findsNothing);
    await tester.tap(find.text('Chưa đọc'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt phòng máy tính'), findsNothing);
    expect(find.text('Xác nhận sử dụng thiết bị'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không khớp');
    await tester.pumpAndSettle();
    expect(find.text('Không có thông báo.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.byTooltip('Cài đặt thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.text('Đánh dấu tất cả đã đọc'));
    await tester.pumpAndSettle();
    expect(find.text('Không có thông báo.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('KTV truy cập thông báo từ chuông và cá nhân', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TechnicianPage(name: 'An', id: 'KTV01'),
      ),
    );
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tùy chỉnh thông báo'));
    await tester.tap(find.text('Tùy chỉnh thông báo'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    Navigator.pop(tester.element(find.byType(BottomSheet)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cài đặt thông báo'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
