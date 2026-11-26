import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/booking/controllers/booking_controller.dart';
import 'package:uth_room_booking/features/booking/data/sample_booking_data.dart';
import 'package:uth_room_booking/features/booking/models/booking.dart';
import 'package:uth_room_booking/features/booking/presentation/schedule_view.dart';
import 'package:uth_room_booking/features/booking/widgets/booking_calendar.dart';
import 'package:uth_room_booking/theme/app_colors.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Trợ lý lọc lịch theo ngày và tìm ca sắp tới', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final room = sampleBookingRooms.first;
    Booking entry(DateTime day, int index, BookingStatus status) => (
      slot: (date: day, asset: room.bookingKey, index: index),
      asset: room,
      section: null,
      studentCount: 10,
      status: status,
    );
    final completed = entry(today, 0, BookingStatus.completed);
    final cancelled = entry(tomorrow, 0, BookingStatus.cancelled);
    final next = entry(tomorrow, 1, BookingStatus.pending);
    final later = entry(tomorrow, 2, BookingStatus.approved);
    final controller = BookingController(
      today: today,
      role: UserRole.student,
      initialBookings: [later, cancelled, next, completed],
    );
    addTearDown(controller.dispose);

    expect(await controller.answerScheduleQuestion(ScheduleQuestion.today), [
      completed,
    ]);
    expect(await controller.answerScheduleQuestion(ScheduleQuestion.tomorrow), [
      next,
      later,
    ]);
    expect(await controller.answerScheduleQuestion(ScheduleQuestion.next), [
      next,
    ]);
  });

  testWidgets('UTH AI giữ và mở lại cuộc trò chuyện từ lịch sử', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShell(name: 'Nguyễn Văn An', id: '21110234'),
      ),
    );
    final assistant = find.byTooltip('Mở UTH AI');
    await tester.ensureVisible(assistant);
    await tester.tap(assistant);
    await tester.pumpAndSettle();
    expect(find.text('UTH AI'), findsOneWidget);
    expect(find.text('Xin chào, An'), findsOneWidget);
    expect(find.text('Trợ lý UTH Lab'), findsOneWidget);
    expect(find.text('Gợi ý nhanh'), findsOneWidget);
    expect(find.byTooltip('Nhập bằng giọng nói'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mai mình có ca nào không?');
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Mai mình có ca nào không?'), findsOneWidget);
    expect(
      find.text('Bạn có thể hỏi về lịch hôm nay, ngày mai hoặc ca tiếp theo.'),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), 'Hôm nay có ca không?');
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay có ca không?'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(assistant);
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay có ca không?'), findsOneWidget);
    expect(find.text('Mai mình có ca nào không?'), findsOneWidget);

    expect(find.byTooltip('Xem lịch của tôi'), findsNothing);
    final options = find.byTooltip('Tùy chọn hội thoại');
    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuộc trò chuyện mới'));
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý nhanh'), findsOneWidget);

    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử trò chuyện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mai mình có ca nào không?'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay có ca không?'), findsOneWidget);
    expect(find.text('Mai mình có ca nào không?'), findsOneWidget);
  });

  testWidgets('UTH AI xác nhận đặt phòng mẫu ngay trong hội thoại', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShell(name: 'Nguyễn Văn An', id: '21110234'),
      ),
    );
    await tester.tap(find.byTooltip('Mở UTH AI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
    final findRooms = find.text('Chiều nay phòng máy nào còn trống?');
    await tester.tap(findRooms);
    await tester.pump();
    expect(find.text('Đang soạn câu trả lời…'), findsOneWidget);
    expect(find.text('Gợi ý nhanh'), findsNothing);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Phòng A2.03'), findsOneWidget);

    expect(find.text('24/40 máy trống'), findsOneWidget);
    final book = find.text('Đặt ngay').first;
    await tester.ensureVisible(book);
    await tester.tap(book);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt phòng'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Đã đặt mẫu'), findsOneWidget);
  });

  testWidgets('lưu xác nhận lưu ý Lịch riêng cho từng tài khoản', (
    tester,
  ) async {
    final bookings = BookingController(
      today: DateTime(2026, 11, 17),
      role: UserRole.student,
      initialBookings: [],
    );
    addTearDown(bookings.dispose);

    Future<void> openSchedule(String account) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleView(bookings: bookings, noticeAccountId: account),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final understood = find.text('Đã hiểu');
    await openSchedule('student-one');
    expect(understood, findsOneWidget);
    await tester.tap(understood);
    await tester.pumpAndSettle();
    await openSchedule('student-one');
    expect(understood, findsNothing);
    await openSchedule('student-two');
    expect(understood, findsOneWidget);
  });

  testWidgets('chấm cam ngày mai chỉ hiện khi có lịch', (tester) async {
    final today = DateTime(2026, 11, 17);
    final tomorrow = DateTime(2026, 11, 18);
    const orange = Color(0xFFE68726);

    Future<void> showCalendar({required bool bookedTomorrow}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCalendar(
              date: today,
              today: today,
              hasSchedule: (day) =>
                  bookedTomorrow && DateUtils.isSameDay(day, tomorrow),
              onDateChanged: (_) {},
            ),
          ),
        ),
      );
    }

    Finder dots(Color color) => find.byWidgetPredicate(
      (widget) => widget is CircleAvatar && widget.backgroundColor == color,
    );

    await showCalendar(bookedTomorrow: false);
    expect(dots(orange), findsNothing);
    expect(dots(AppColors.primary), findsOneWidget);
    await showCalendar(bookedTomorrow: true);
    expect(dots(orange), findsOneWidget);
    expect(dots(AppColors.primary), findsOneWidget);
  });

  test('sinh viên chỉ giữ một phòng trong cùng ca và ngày', () {
    final today = DateTime(2026, 11, 17);
    final day = DateTime(2026, 11, 18);
    final tomorrow = DateTime(2026, 11, 19);
    final bookings = BookingController(
      today: today,
      role: UserRole.student,
      initialBookings: [],
    );
    final first = sampleBookingRooms.first;
    final second = sampleBookingRooms[1];
    final equipment = sampleBookingEquipment.first;
    final firstSlot = (date: day, asset: first.name, index: 2);
    final secondSlot = (date: day, asset: second.name, index: 2);

    expect(bookings.register(firstSlot, first, null, studentCount: 10), isTrue);
    expect(bookings.hasStudentRoomBooking(day, 2), isTrue);
    expect(
      bookings.register(secondSlot, second, null, studentCount: 10),
      isFalse,
    );
    expect(bookings.hasStudentRoomBooking(tomorrow, 2), isFalse);
    expect(bookings.hasStudentRoomBooking(day, 3), isFalse);
    expect(
      bookings.register(
        (date: day, asset: equipment.name, index: 2),
        equipment,
        null,
      ),
      isTrue,
    );
    expect(bookings.cancel(0), isTrue);
    expect(
      bookings.register(secondSlot, second, null, studentCount: 10),
      isTrue,
    );
    expect(bookings.indicesFor(day, cancelledLast: true), [2, 1, 0]);
    expect(bookings.cancel(2), isTrue);
    expect(bookings.indicesFor(day, cancelledLast: true), [1, 2, 0]);
  });

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
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng thư viện'), findsNothing);
    await tester.tap(find.text('Ca 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng B1-201'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    await tester.tap(
      find.descendant(of: sheet, matching: find.byIcon(Icons.arrow_drop_down)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CN2302E · Lập trình Web').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng B1-201'), findsOneWidget);
    expect(find.text('Mã học phần'), findsWidgets);
    expect(find.text('Lập trình Web'), findsOneWidget);
    expect(find.text('13:00 – 15:00'), findsWidgets);
    expect(find.text('Chờ duyệt'), findsOneWidget);

    await tester.tap(find.text('Thiết bị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ổ điện'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('Lớp học phần')),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đặt thiết bị'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Ổ điện'), findsOneWidget);
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
    await tester.tap(find.text('Đã hiểu'));
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
    await tester.tap(find.widgetWithText(TextButton, 'Xác nhận'));
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
