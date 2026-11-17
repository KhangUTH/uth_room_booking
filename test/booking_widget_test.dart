import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

void main() {
  testWidgets('giảng viên gắn lớp học phần vào ca và xem lại chi tiết', (
    tester,
  ) async {
    await useMobileScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(
          name: 'Trần Minh Khoa',
          id: 'GV00871',
          role: UserRole.teacher,
        ),
      ),
    );
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ca 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng B1-201'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    await tester.tap(
      find.descendant(of: sheet, matching: find.byIcon(Icons.arrow_drop_down)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CNTT301 · Lập trình di động').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng B1-201'), findsOneWidget);
    expect(find.text('Mã học phần'), findsWidgets);
    expect(find.text('Lập trình di động'), findsOneWidget);
    expect(find.text('13:00 – 15:00'), findsWidgets);
    expect(find.text('Chờ duyệt'), findsOneWidget);
  });

  testWidgets('chọn phòng và xem ca vừa đăng ký trong lịch của tôi', (
    tester,
  ) async {
    await useMobileScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(name: 'Nguyễn Văn An', id: '21110234'),
      ),
    );

    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng B2-304'), findsOneWidget);
    expect(find.text('Phòng B2-305'), findsOneWidget);
    expect(find.text('Phòng B1-201'), findsOneWidget);
    expect(find.text('Phòng thư viện'), findsOneWidget);

    await tester.tap(find.text('Ca 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng B1-201'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();
    final studentCount = find.byType(TextFormField);
    await tester.enterText(studentCount, '9');
    await tester.tap(find.text('Đặt phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Cần ít nhất 10 sinh viên'), findsOneWidget);
    await tester.enterText(studentCount, '10');
    await tester.tap(find.text('Đặt phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();

    expect(find.text('Phòng B1-201'), findsOneWidget);
    expect(find.text('Số sinh viên'), findsOneWidget);
    expect(find.text('13:00 – 15:00'), findsWidgets);
    expect(find.text('Chờ duyệt'), findsOneWidget);
    await tester.tap(find.text('Hủy lịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(find.text('Hủy lịch'), findsNothing);

    await tester.tap(find.text('Thiết bị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ca 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ổ điện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt thiết bị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Ổ điện'), findsOneWidget);
    expect(find.text('Phòng B1-201'), findsOneWidget);

    await tester.tap(find.byTooltip('Tuần sau'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có đăng ký trong ngày này'), findsOneWidget);
    await tester.tap(find.text('Tất cả ngày'));
    await tester.pumpAndSettle();
    expect(find.text('Ổ điện'), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    final history = find.text('Lịch sử');
    await tester.ensureVisible(history);
    await tester.tap(history);
    await tester.pumpAndSettle();
    expect(find.text('Lịch sử đăng ký'), findsOneWidget);
    expect(find.text('Phòng B1-201'), findsOneWidget);
    expect(find.text('Đã hủy'), findsOneWidget);
    await tester.tap(find.text('Thiết bị'));
    await tester.pumpAndSettle();
    expect(find.text('Ổ điện'), findsOneWidget);
    expect(find.text('Phòng B1-201'), findsNothing);
  });
}
