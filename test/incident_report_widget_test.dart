import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/incident_report/data/incident_report_store.dart';
import 'package:uth_room_booking/features/incident_report/models/incident_report.dart';
import 'package:uth_room_booking/features/technician/data/demo_incident_queue.dart';
import 'package:uth_room_booking/features/technician/widgets/technician_task_card.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

class _RetryReportStore extends IncidentReportStore {
  _RetryReportStore(SupabaseClient client) : super(client, 'test-user');

  final attempts = <String>[];
  StoredIncidentReport? stored;

  @override
  Future<List<StoredIncidentReport>> history() async => [?stored];

  @override
  Future<StoredIncidentReport> submit(
    String submissionId,
    IncidentReport report,
  ) async {
    attempts.add(submissionId);
    if (attempts.length == 1) throw StateError('Offline');
    return stored = (
      id: submissionId,
      report: (
        id: 42,
        title: report.title,
        description: report.description,
        type: report.type,
        asset: report.asset,
        course: report.course,
        needsSupport: report.needsSupport,
        occurredAt: report.occurredAt,
        submittedAt: report.submittedAt,
        photos: report.photos,
      ),
      status: IncidentStatus.pending,
      updatedAt: null,
      hasPhoto: false,
    );
  }
}

void main() {
  testWidgets('gửi báo cáo lại sau khi mất mạng vẫn giữ nội dung', (
    tester,
  ) async {
    await useMobileScreen(tester);
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    addTearDown(() => tester.runAsync(client.dispose));
    final store = _RetryReportStore(client);
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          name: 'Sinh viên kiểm thử',
          id: 'SV01',
          incidentStore: store,
        ),
      ),
    );
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng A101').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'Máy không khởi động');
    await tester.enterText(fields.last, 'Màn hình đen');
    final submit = find.text('Gửi báo cáo');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.text('Không gửi được báo cáo. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Máy không khởi động'), findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(store.attempts.length, 2);
    expect(store.attempts.toSet(), hasLength(1));
    expect(find.text('Mã báo cáo #SC-0042'), findsOneWidget);
    expect(store.stored?.report.description, 'Màn hình đen');
    await unmountApp(tester);
  });

  testWidgets('chỉ gọi bộ chọn ảnh khi người dùng chọn nguồn', (tester) async {
    await useMobileScreen(tester);
    const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
    final messenger = tester.binding.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(pickerChannel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(pickerChannel, null));

    await tester.pumpWidget(
      const MaterialApp(
        home: MainShell(name: 'Sinh viên demo', id: '21110234'),
      ),
    );
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    final addPhoto = find.text('Thêm ảnh');
    await tester.ensureVisible(addPhoto);
    await tester.tap(addPhoto);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.text('Chụp ảnh'), findsOneWidget);
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'pickImage');
    expect(calls.single.arguments['requestFullMetadata'], isFalse);
    expect(find.text('Thêm ảnh'), findsOneWidget);
  });

  testWidgets('gửi báo cáo mẫu rồi mở lại từ báo cáo của tôi', (tester) async {
    await useMobileScreen(tester);
    final queue = DemoIncidentQueue();
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(
          name: 'Nguyễn Văn An',
          id: '21110234',
          incidentQueue: queue,
        ),
      ),
    );
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Mức độ'), findsNothing);
    expect(find.text('Cần hỗ trợ ngay trong giờ dạy'), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng A101').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Máy không khởi động');
    await tester.enterText(fields.at(1), 'Màn hình đen sau khi bấm nguồn');
    final submit = find.text('Gửi báo cáo');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Mã báo cáo #SC-0001'), findsOneWidget);
    expect(queue.tasks.single.title, 'Máy không khởi động');
    expect(queue.tasks.single.scheduledAt, isNull);
    expect(find.text('Màn hình đen sau khi bấm nguồn'), findsOneWidget);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Chờ tiếp nhận'), findsOneWidget);
    await tester.tap(find.text('Máy không khởi động'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng máy · Phòng A101'), findsOneWidget);
    await tester.tap(find.text('Hủy báo cáo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(queue.tasks, isEmpty);
  });

  testWidgets('giảng viên phải nhập lớp khi cần hỗ trợ trong giờ dạy', (
    tester,
  ) async {
    await useMobileScreen(tester);
    final incidentQueue = DemoIncidentQueue();
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) =>
            AppRouter.onGenerateRoute(settings, incidentQueue: incidentQueue),
        home: MainShell(
          name: 'Trần Minh Khoa',
          id: 'GV00871',
          role: UserRole.teacher,
          incidentQueue: incidentQueue,
        ),
      ),
    );
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Lớp học phần đang dạy'), findsOneWidget);
    expect(find.text('Mức độ'), findsNothing);

    final support = find.text('Cần hỗ trợ ngay trong giờ dạy');
    await tester.ensureVisible(support);
    await tester.tap(support);
    await tester.pumpAndSettle();
    final submit = find.text('Gửi báo cáo');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập lớp học phần đang dạy'), findsOneWidget);

    final roomMenu = find.byIcon(Icons.arrow_drop_down);
    await tester.ensureVisible(roomMenu);
    await tester.tap(roomMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng A101').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lập trình di động - Nhóm 02');
    await tester.enterText(fields.at(1), 'Máy chiếu không lên hình');
    await tester.enterText(fields.at(2), 'Lớp đang học tại phòng A101');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Cần hỗ trợ ngay')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('Lập trình di động - Nhóm 02'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Cần hỗ trợ ngay'), findsOneWidget);

    Navigator.of(tester.element(find.byType(MainShell)))
        .pushReplacementNamed<void, void>(
          AppRoute.home,
          arguments: (
            name: 'Kỹ thuật viên demo',
            id: 'KT-0217',
            role: UserRole.technician,
            faculty: null,
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Máy chiếu không lên hình'), findsOneWidget);
    expect(find.text('Phòng A101'), findsOneWidget);
    expect(find.text('Trước 23:59 hôm nay'), findsOneWidget);
    final reportCard = find.widgetWithText(
      TechnicianTaskCard,
      'Máy chiếu không lên hình',
    );
    expect(
      tester.widget(find.byType(TechnicianTaskCard).first),
      same(tester.widget(reportCard)),
    );
    Finder reportAction(String label) => find.descendant(
      of: reportCard,
      matching: find.widgetWithText(FilledButton, label),
    );
    await tester.tap(reportAction('Nhận việc'));
    await tester.pumpAndSettle();
    expect(reportAction('Hoàn tất'), findsOneWidget);
    Navigator.of(tester.element(find.byType(MainShell)))
        .pushReplacementNamed<void, void>(
          AppRoute.home,
          arguments: (
            name: 'Trần Minh Khoa',
            id: 'gv00871',
            role: UserRole.teacher,
            faculty: null,
          ),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Đang xử lý'), findsOneWidget);
    await tester.tap(find.text('Máy chiếu không lên hình'));
    await tester.pumpAndSettle();
    expect(find.text('Hủy báo cáo'), findsNothing);
    expect(find.textContaining('Đang xử lý lúc'), findsOneWidget);
  });
}
