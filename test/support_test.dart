import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/features/support/presentation/support_page.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_page.dart';
import 'package:uth_room_booking/shared/layouts/footer.dart';
import 'package:uth_room_booking/shared/layouts/homepage.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openStudentHome(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const HomePage(name: 'Nguyễn An', id: 'SV001'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openSupport(WidgetTester tester) async {
  await openStudentHome(tester);
  await tester.tap(find.text('Tôi'));
  await tester.pumpAndSettle();
  if (find.text('Trung tâm hỗ trợ').evaluate().isNotEmpty) {
    await tapVisible(tester, find.text('Trung tâm hỗ trợ'));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'trung tâm dùng footer chung, mở hướng dẫn và quay lại bằng nút Back',
    (tester) async {
      await openSupport(tester);
      expect(find.text('TRUNG TÂM\nHỖ TRỢ'), findsOneWidget);
      expect(find.byType(MyFooter), findsOneWidget);
      await tapVisible(tester, find.text('Hướng dẫn sử dụng'));
      expect(find.text('HƯỚNG DẪN\nSỬ DỤNG'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('TRUNG TÂM\nHỖ TRỢ'), findsOneWidget);
      await tapVisible(tester, find.text('Câu hỏi thường gặp'));
      await tapVisible(
        tester,
        find.text('Tôi có bắt buộc đính kèm ảnh không?'),
      );
      expect(find.textContaining('Ảnh minh chứng là tùy chọn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('kiểm tra email, lưu liên hệ và giữ bản mẫu khi chuyển tab', (
    tester,
  ) async {
    await openSupport(tester);
    await tapVisible(tester, find.text('Liên hệ hỗ trợ'));
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(1), 'sai-email');
    await tester.enterText(fields.at(2), 'Tôi cần hỗ trợ đăng ký phòng.');
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'Gửi liên hệ'),
    );
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.text('Đã lưu bản mẫu'), findsNothing);
    await tester.enterText(fields.at(1), 'an@example.com');
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'Gửi liên hệ'),
    );
    expect(find.text('Đã lưu bản mẫu'), findsOneWidget);
    await tapVisible(tester, find.text('Đã hiểu'));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    if (find.text('Trung tâm hỗ trợ').evaluate().isNotEmpty) {
      await tapVisible(tester, find.text('Trung tâm hỗ trợ'));
    }
    await tester.pumpAndSettle();
    expect(find.text('an@example.com'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Về trung tâm hỗ trợ'));
    await tapVisible(tester, find.text('Bản mẫu đã lưu (1)'));
    await tapVisible(tester, find.text('Liên hệ hỗ trợ').last);
    expect(find.text('Email: an@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'báo cáo phòng yêu cầu loại, phòng, mô tả và không bắt buộc ảnh',
    (tester) async {
      await openStudentHome(tester);
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Báo cáo sự cố'),
      );
      expect(find.text('Vui lòng chọn loại sự cố'), findsOneWidget);
      expect(find.text('Vui lòng chọn phòng'), findsOneWidget);
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tapVisible(tester, dropdowns.at(0));
      await tapVisible(tester, find.text('Phòng máy').last);
      await tapVisible(tester, dropdowns.at(1));
      await tapVisible(tester, find.text('Phòng A101').last);
      await tester.enterText(
        find.byType(TextFormField),
        'Đèn trong phòng không sáng.',
      );
      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Báo cáo sự cố'),
      );
      expect(find.text('Đã lưu bản mẫu'), findsOneWidget);
      await tapVisible(tester, find.text('Đã hiểu'));
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Trung tâm hỗ trợ'));
      await tapVisible(tester, find.text('Bản mẫu đã lưu (1)'));
      await tapVisible(tester, find.text('Báo cáo sự cố').last);
      expect(find.text('Mô tả: Đèn trong phòng không sáng.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('kỹ thuật viên không có trung tâm hỗ trợ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TechnicianPage(name: 'Kỹ thuật viên', id: 'KTV01'),
      ),
    );
    expect(find.text('Hỗ trợ'), findsNothing);
    expect(find.byType(SupportPage, skipOffstage: false), findsNothing);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .items
          .length,
      3,
    );
  });
}
