import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';
import 'package:uth_room_booking/shared/layouts/header.dart';

import 'support/widget_test_helpers.dart';

void main() {
  testWidgets('chuông trên tab Cá nhân và Trang chủ mở cùng hộp thông báo', (
    tester,
  ) async {
    await useMobileScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(name: 'Nguyễn Văn An', id: '21110234'),
      ),
    );
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Lưu thông báo').first);
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt phòng máy tính'), findsOneWidget);
    expect(find.text('Xác nhận sử dụng thiết bị'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xem tất cả'));
    await tester.tap(find.text('Xem tất cả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt phòng máy tính'), findsOneWidget);
    expect(find.text('Xác nhận sử dụng thiết bị'), findsNothing);
  });

  testWidgets('hộp thoại chỉnh sửa rộng và có khoảng cách giữa các ô', (
    tester,
  ) async {
    await useMobileScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(name: 'Nguyễn Văn An', id: '21110234'),
      ),
    );
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final fields = find.descendant(
      of: dialog,
      matching: find.byType(TextFormField),
    );
    expect(fields, findsNWidgets(2));
    expect(
      tester
          .getSize(
            find.descendant(of: dialog, matching: find.byType(Material)).first,
          )
          .width,
      368,
    );
    for (var index = 1; index < 2; index++) {
      expect(
        tester.getTopLeft(fields.at(index)).dy -
            tester.getBottomLeft(fields.at(index - 1)).dy,
        16,
      );
    }
  });

  testWidgets('bốn tab dùng chung AppBar và thanh điều hướng', (tester) async {
    await useMobileScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(name: 'Nguyễn Văn An', id: '21110234'),
      ),
    );

    const labels = ['Trang chủ', 'Lịch', 'Báo cáo', 'Cá nhân'];
    const bodyTexts = [
      'Bạn muốn đăng ký gì?',
      'Chọn ca',
      'Loại sự cố',
      'Thông tin cá nhân',
    ];
    final navigation = find.byType(BottomNavigationBar);

    for (final index in [1, 2, 3, 0]) {
      await tester.tap(
        find.descendant(of: navigation, matching: find.text(labels[index])),
      );
      await tester.pumpAndSettle();

      final header = find.byType(MyHeader);
      expect(
        find.descendant(of: header, matching: find.text('Nguyễn Văn An')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('MSSV: 21110234')),
        findsOneWidget,
      );
      expect(
        tester.widget<BottomNavigationBar>(navigation).currentIndex,
        index,
      );
      expect(find.text(bodyTexts[index]), findsOneWidget);
      if (index != 0) {
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.widget<BottomNavigationBar>(navigation).currentIndex, 0);
      }
    }
  });
}
