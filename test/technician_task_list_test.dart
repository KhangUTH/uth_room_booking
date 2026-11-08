import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/features/technician/models/task_filter.dart';
import 'package:uth_room_booking/features/technician/models/technician_task.dart';
import 'package:uth_room_booking/features/technician/presentation/task_details_page.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_home_page.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_page.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_schedule_page.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

TechnicianTask task(String title, TaskStatus status, DateTime date) =>
    TechnicianTask(
      title: title,
      status: status,
      scheduledAt: date,
      location: 'Phòng A101',
      description: 'Kiểm tra thiết bị',
      reporter: 'Sinh viên',
      priority: TaskPriority.medium,
    );

List<TechnicianTask> fixtures() {
  final past = DateTime.now().subtract(const Duration(days: 1));
  final future = DateTime.now().add(const Duration(days: 1));
  return [
    task('Phiếu chờ', TaskStatus.pending, future),
    task('Phiếu chờ quá hạn', TaskStatus.pending, past),
    task('Phiếu đã nhận', TaskStatus.accepted, future),
    task('Phiếu đang sửa quá hạn', TaskStatus.inProgress, past),
    task('Phiếu hoàn tất', TaskStatus.completed, past),
  ];
}

Future<void> openHome(
  WidgetTester tester,
  List<TechnicianTask> tasks,
  VoidCallback onChanged,
) async {
  await tester.binding.setSurfaceSize(const Size(320, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, refresh) => TechnicianHomePage(
            name: 'Kỹ thuật viên',
            id: 'KTV01',
            tasks: tasks,
            onChanged: () => refresh(onChanged),
          ),
        ),
      ),
    ),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('quá hạn chỉ gồm phiếu chưa hoàn tất và đã qua thời gian dự kiến', () {
    final now = DateTime(2026, 11, 8, 10);
    final item = task('Phiếu', TaskStatus.pending, now);
    expect(TaskFilter.overdue.matches(item, now), isFalse);
    final later = now.add(const Duration(seconds: 1));
    expect(TaskFilter.overdue.matches(item, later), isTrue);
    item.status = TaskStatus.accepted;
    expect(TaskFilter.active.matches(item, later), isTrue);
    expect(TaskFilter.overdue.matches(item, later), isTrue);
    item.status = TaskStatus.completed;
    expect(TaskFilter.overdue.matches(item, later), isFalse);
    expect(TaskFilter.completed.matches(item, later), isTrue);
  });

  testWidgets('ô thống kê lọc tại chỗ, không mở trang danh sách mới', (
    tester,
  ) async {
    final tasks = fixtures();
    await openHome(tester, tasks, () {});
    for (final filter in TaskFilter.values) {
      final matches = tasks
          .where((item) => filter.matches(item, DateTime.now()))
          .length;
      final stat = find.byKey(ValueKey('task-stat-${filter.name}'));
      await tapVisible(tester, stat);
      expect(find.text('${filter.label} · $matches công việc'), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.byType(TechnicianHomePage)))!.isFirst,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('xử lý liên tục trong chi tiết và đồng bộ số đếm khi quay lại', (
    tester,
  ) async {
    final tasks = fixtures();
    var changes = 0;
    await openHome(tester, tasks, () => changes++);
    await tester.scrollUntilVisible(
      find.text('Phiếu chờ'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tapVisible(tester, find.text('Phiếu chờ'));
    await tester.tap(find.text('Nhận việc'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsPage), findsOneWidget);
    expect(find.text('Trạng thái: Đã nhận'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu xử lý'));
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Đang xử lý'), findsOneWidget);
    await tester.tap(find.text('Hoàn tất công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Đã xong'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(changes, 3);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Phiếu chờ'), findsNothing);
    final completed = find.byKey(const ValueKey('task-stat-completed'));
    await tapVisible(tester, completed);
    expect(find.text('Đã xong · 2 công việc'), findsOneWidget);
    expect(
      find.descendant(of: completed, matching: find.text('2')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lọc loại, tìm kiếm và xem mọi trạng thái trong cùng danh sách', (
    tester,
  ) async {
    final tasks = fixtures();
    tasks[2] = TechnicianTask(
      title: 'Phiếu bảo trì',
      location: 'A101',
      description: 'Bảo trì định kỳ',
      reporter: 'Nhà trường',
      scheduledAt: DateTime.now(),
      priority: TaskPriority.medium,
      isMaintenance: true,
      status: TaskStatus.accepted,
    );
    await openHome(tester, tasks, () {});
    await tapVisible(tester, find.text('Tất cả'));
    expect(find.text('Tất cả trạng thái · 5 công việc'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('task-type-2')));
    expect(find.text('Tất cả trạng thái · 1 công việc'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('task-type-1')));
    expect(find.text('Tất cả trạng thái · 4 công việc'), findsOneWidget);
    final search = find.byType(TextField);
    await tester.ensureVisible(search);
    await tester.enterText(search, ' KHÔNG KHỚP ');
    await tester.pumpAndSettle();
    expect(find.text('Không có công việc phù hợp.'), findsOneWidget);
    await tester.enterText(search, 'a101');
    await tester.pumpAndSettle();
    expect(find.text('Tất cả trạng thái · 4 công việc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ba tab giữ bộ lọc công việc khi chuyển qua lịch và cá nhân', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TechnicianPage(name: 'KTV', id: '01'),
      ),
    );
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .items
          .length,
      3,
    );
    await tapVisible(tester, find.byKey(const ValueKey('task-stat-completed')));
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Đã xong · 1 công việc'), findsOneWidget);
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Thông tin cá nhân'));
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );
    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Đã xong · 1 công việc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lịch theo ngày giữ công việc hoàn tất và lọc khi cần', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final nextDay = now.weekday == 7
        ? now.subtract(const Duration(days: 1))
        : now.add(const Duration(days: 1));
    final tasks = [
      task('Đã xong ngày khác', TaskStatus.completed, nextDay),
      task('Đang sửa ngày khác', TaskStatus.inProgress, nextDay),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TechnicianSchedulePage(
            name: 'KTV',
            id: '01',
            tasks: tasks,
            onChanged: () {},
          ),
        ),
      ),
    );
    await tapVisible(tester, find.text('${nextDay.day}'.padLeft(2, '0')));
    expect(
      find.text('Lịch ngày ${nextDay.day}/${nextDay.month}/${nextDay.year}'),
      findsOneWidget,
    );
    expect(find.text('Đã xong ngày khác'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Chưa hoàn tất'));
    expect(find.text('Đã xong ngày khác'), findsNothing);
    expect(find.text('Đang sửa ngày khác'), findsOneWidget);
    expect(find.text('Hoàn tất'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
