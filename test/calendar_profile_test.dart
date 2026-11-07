import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/features/calendar/presentation/calendar_page.dart';
import 'package:uth_room_booking/features/profile/presentation/personal_info_page.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_page.dart';
import 'package:uth_room_booking/shared/layouts/homepage.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

Future<void> usePhone(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tab lịch mở trang mới và lịch tháng giữ khi đổi tab', (
    tester,
  ) async {
    await usePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const HomePage(name: 'An', id: 'SV01'),
      ),
    );
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
    await tapShown(tester, find.byKey(const ValueKey('next-month')));
    final next = DateTime(DateTime.now().year, DateTime.now().month + 1);
    final month = 'tháng ${next.month} ${next.year}';
    expect(find.text(month), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.text(month), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lịch hiển thị sự kiện từ tệp được nhập và đổi năm đúng', (
    tester,
  ) async {
    await usePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: CalendarPage(initialDate: DateTime(2026, 10))),
      ),
    );
    await tapShown(tester, find.text('23'));
    expect(find.text('010412620229 - Học kỳ doanh nghiệp'), findsOneWidget);
    expect(find.text('LMS'), findsOneWidget);
    await tapShown(tester, find.byKey(const ValueKey('next-month')));
    await tapShown(tester, find.byKey(const ValueKey('next-month')));
    await tapShown(tester, find.byKey(const ValueKey('next-month')));
    expect(find.text('tháng 1 2027'), findsOneWidget);
    expect(find.text('010412620229 - Học kỳ doanh nghiệp'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cập nhật hồ sơ đồng bộ header, giữ email và không lẫn tài khoản',
    (tester) async {
      await usePhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const HomePage(name: 'An', id: 'SV01'),
        ),
      );
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tapShown(tester, find.text('Thông tin cá nhân'));
      expect(find.byType(PersonalInfoPage), findsOneWidget);
      expect(find.text('An'), findsOneWidget);
      expect(find.text('SV01'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Nguyễn An');
      await tester.enterText(fields.at(2), 'an@example.com');
      await tester.enterText(fields.at(3), '0901234567');
      await tapShown(tester, find.text('Cập Nhật'));
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalInfoPage), findsNothing);
      expect(find.text('Tên: Nguyễn An'), findsOneWidget);
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tapShown(tester, find.text('Thông tin cá nhân'));
      expect(find.text('an@example.com'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const HomePage(name: 'Bình', id: 'GV02'),
        ),
      );
      await tester.tap(find.text('Tôi'));
      await tester.pumpAndSettle();
      await tapShown(tester, find.text('Thông tin cá nhân'));
      expect(find.text('Bình'), findsOneWidget);
      expect(find.text('an@example.com'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hồ sơ kỹ thuật viên dùng đúng footer và trở về lịch công việc', (
    tester,
  ) async {
    await usePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TechnicianPage(name: 'Kỹ thuật viên', id: 'KTV01'),
      ),
    );
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tapShown(tester, find.text('Thông tin cá nhân'));
    expect(find.widgetWithText(TextField, 'Mã KTV'), findsOneWidget);
    expect(find.text('Hỗ trợ'), findsNothing);
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch công việc'), findsOneWidget);
    expect(find.byType(CalendarPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
