import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/booking/models/booking.dart';
import 'package:uth_room_booking/features/incident_report/data/incident_report_store.dart';
import 'package:uth_room_booking/features/incident_report/models/incident_report.dart';
import 'package:uth_room_booking/features/incident_report/widgets/incident_report_details_sheet.dart';
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
    IncidentReport report, {
    void Function(bool)? onPhotoUploadChanged,
  }) async {
    attempts.add(submissionId);
    if (attempts.length < 3) throw StateError('Offline');
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
        submittedAt: report.submittedAt,
        photos: report.photos,
      ),
      status: IncidentStatus.pending,
      updatedAt: null,
      hasPhoto: false,
      canCancel: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final role in [UserRole.student, UserRole.teacher]) {
    testWidgets('lọc phòng máy trong báo cáo của ${role.name}', (tester) async {
      await useMobileScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            name: 'Người báo cáo',
            id: 'Test01',
            role: role,
            loadCatalog: () async => (
              rooms: [
                for (final name in [
                  'Phòng H507',
                  'Phòng thư viện',
                  'Phòng I101',
                ])
                  (
                    name: name,
                    detail: 'Tầng 1',
                    capacity: 20,
                    slots: List.filled(
                      bookingStartTimes.length,
                      name == 'Phòng I101'
                          ? SlotStatus.maintenance
                          : SlotStatus.free,
                    ),
                  ),
              ],
              equipment: <BookingAsset>[],
              namesById: <String, String>{},
              roomsUnavailableToTeachers: {'Phòng thư viện'},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
      await tester.pumpAndSettle();

      expect(find.text('Phòng H507'), findsOneWidget);
      expect(find.text('Phòng I101'), findsNothing);
      expect(
        find.text('Phòng thư viện'),
        role == UserRole.student ? findsOneWidget : findsNothing,
      );
      await unmountApp(tester);
    });
  }

  for (final lostResponse in [false, true]) {
    test('gửi JPEG trực tiếp, mất phản hồi: $lostResponse', () async {
      late Uint8List uploaded;
      final uploadStates = <bool>[];
      final uploadClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          startsWith('/storage/v1/object/incident-images/'),
        );
        expect(request.url.path, endsWith('.jpg'));
        expect(request.headers['content-type'], 'image/jpeg');
        expect(request.headers['authorization'], 'Bearer test-access-token');
        expect(request.headers['apikey'], 'test-key');
        expect(request.headers['x-upsert'], 'true');
        expect(uploadStates, [true]);
        uploaded = request.bodyBytes;
        expect(uploaded.take(2), [0xff, 0xd8]);
        final codec = await ui.instantiateImageCodec(uploaded);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 288);
        expect(frame.image.height, 720);
        frame.image.dispose();
        codec.dispose();
        expect(uploaded.lengthInBytes, lessThanOrEqualTo(512 * 1024));
        if (lostResponse) throw http.ClientException('Connection closed');
        return http.Response('', 200);
      });
      addTearDown(uploadClient.close);
      final client = SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/storage/')) {
            expect(uploadStates, [true]);
            expect(request.method, 'GET');
            expect(lostResponse, isTrue);
            return http.Response.bytes(uploaded, 200);
          }
          if (path.endsWith('/rooms')) {
            return http.Response('{"id":"room-id"}', 200, request: request);
          }
          if (request.method == 'GET') {
            return http.Response('[]', 200, request: request);
          }
          expect(jsonDecode(request.body)['has_photo'], isTrue);
          expect(uploadStates, [true, false]);
          return http.Response(
            '{"id":"report-id","report_number":42,"title":"Máy hỏng",'
            '"created_at":"2026-11-17T11:00:00Z","status":"open",'
            '"has_photo":true,"rooms":{"name":"Phòng A101"}}',
            201,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.recoverSession(
        jsonEncode({
          'access_token': 'test-access-token',
          'refresh_token': 'test-refresh-token',
          'token_type': 'bearer',
          'user': {
            'id': 'test-user',
            'aud': 'authenticated',
            'created_at': '',
            'app_metadata': {},
          },
        }),
      );
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.teal, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(480, 1200);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      image.dispose();
      picture.dispose();
      final store = IncidentReportStore(
        client,
        'test-user',
        uploadClient: uploadClient,
      );
      final result = await store.submit(store.newSubmissionId(), (
        id: 0,
        title: 'Máy hỏng',
        description: 'Màn hình đen',
        type: 'Phòng máy',
        asset: 'Phòng A101',
        course: '',
        needsSupport: false,
        submittedAt: DateTime.now(),
        photos: [png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes)],
      ), onPhotoUploadChanged: uploadStates.add);
      expect(result.hasPhoto, isTrue);
    });
  }

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
    await tester.enterText(fields.last, 'Màn hình đen sau khi khởi động');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(store.attempts.length, 3);
    expect(store.attempts.last, isNot(store.attempts.first));
    expect(find.text('Mã báo cáo #SC-0042'), findsOneWidget);
    expect(find.text('Hủy báo cáo'), findsNothing);
    expect(find.text('Thời gian gửi báo cáo'), findsOneWidget);
    expect(store.stored?.report.description, 'Màn hình đen sau khi khởi động');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final saved = store.stored!;
    for (final status in [
      IncidentStatus.inProgress,
      IncidentStatus.completed,
    ]) {
      store.stored = (
        id: saved.id,
        report: saved.report,
        status: status,
        updatedAt: saved.report.submittedAt,
        hasPhoto: saved.hasPhoto,
        canCancel: false,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final sheet = tester.widget<IncidentReportDetailsSheet>(
        find.byType(IncidentReportDetailsSheet),
      );
      expect(sheet.status, status);
    }
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
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(queue.tasks, isEmpty);
  });

  testWidgets('giảng viên chọn lớp đã phân công khi cần hỗ trợ trong giờ dạy', (
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
    await tester.tap(find.text('Thiết bị'));
    await tester.pumpAndSettle();
    expect(find.text('Lớp học phần đang dạy'), findsNothing);
    expect(support, findsNothing);
    await tester.tap(find.text('Phòng máy'));
    await tester.pumpAndSettle();
    expect(find.text('Lớp học phần đang dạy'), findsOneWidget);
    await tester.ensureVisible(support);
    await tester.tap(support);
    await tester.pumpAndSettle();
    final submit = find.text('Gửi báo cáo');
    expect(find.text('Bắt buộc khi cần hỗ trợ ngay'), findsNothing);

    final roomMenu = find.byKey(const ValueKey('incident-asset-menu'));
    await tester.ensureVisible(roomMenu);
    await tester.tap(roomMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng A101').last);
    await tester.pumpAndSettle();
    final courseMenu = find.byKey(const ValueKey('incident-course-menu'));
    await tester.ensureVisible(courseMenu);
    await tester.tap(courseMenu);
    await tester.pumpAndSettle();
    const course = 'CN2302E · Lập trình Web';
    await tester.tap(find.text(course).last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Máy chiếu không lên hình');
    await tester.enterText(fields.at(1), 'Lớp đang học tại phòng A101');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Cần hỗ trợ ngay')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text(course)),
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
