import 'dart:async';
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
import 'package:uth_room_booking/features/incident_report/data/incident_report_store.dart';
import 'package:uth_room_booking/features/incident_report/models/incident_report.dart';
import 'package:uth_room_booking/features/incident_report/widgets/incident_report_form.dart';
import 'package:uth_room_booking/features/technician/data/demo_incident_queue.dart';
import 'package:uth_room_booking/features/technician/widgets/technician_task_card.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

class _RetryReportStore extends IncidentReportStore {
  _RetryReportStore(SupabaseClient client) : super(client, 'test-user');

  final attempts = <String>[];
  StoredIncidentReport? stored;
  bool failAssets = false;
  int historyCalls = 0;

  @override
  Future<IncidentAssets> assets() async {
    if (failAssets) throw StateError('Offline');
    return (rooms: {'room-a101': 'Phòng A101'}, equipment: <String, String>{});
  }

  @override
  Future<List<StoredIncidentReport>> history() async {
    historyCalls++;
    return [?stored];
  }

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
        assetId: report.assetId,
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

Future<SupabaseClient> _authenticatedClient(
  Future<http.Response> Function(http.Request) handler,
) async {
  final client = SupabaseClient(
    'https://example.com',
    'test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient(handler),
  );
  await client.auth.recoverSession(
    jsonEncode(
      Session(
        accessToken: 'test-token',
        refreshToken: 'refresh-token',
        tokenType: 'bearer',
        user: const User(
          id: 'test-user',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        ),
      ),
    ),
  );
  return client;
}

IncidentReport _report({
  bool equipment = false,
  List<Uint8List> photos = const [],
}) => (
  id: 0,
  title: 'Máy lỗi',
  description: 'Không lên nguồn',
  type: equipment ? 'Thiết bị' : 'Phòng máy',
  asset: 'Tên trước khi đổi',
  assetId: equipment ? 'device-id' : 'room-id',
  course: 'Nhóm 02',
  needsSupport: true,
  occurredAt: DateTime.utc(2026, 11, 17, 1),
  submittedAt: DateTime.utc(2026, 11, 17, 2),
  photos: photos,
);

Map<String, dynamic> _row({bool equipment = false, String status = 'open'}) => {
  'id': 'saved-id',
  'report_number': 42,
  'title': 'Máy lỗi',
  'description': 'Không lên nguồn',
  'status': status,
  'room_id': equipment ? null : 'room-id',
  'equipment_id': equipment ? 'device-id' : null,
  'rooms': equipment ? null : {'name': 'Tên hiện tại'},
  'equipment': equipment ? {'name': 'Thiết bị hiện tại'} : null,
  'course_section': 'Nhóm 02',
  'needs_support': true,
  'has_photo': false,
  'occurred_at': '2026-11-17T01:00:00Z',
  'created_at': '2026-11-17T02:00:00Z',
  'status_updated_at': null,
};

http.Response _jsonResponse(
  http.Request request,
  Object? body, [
  int status = 200,
]) => http.Response(
  jsonEncode(body),
  status,
  request: request,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'lớp học phần báo cáo chỉ lấy các lớp được giao cho tài khoản',
    () async {
      final client = await _authenticatedClient((request) async {
        expect(request.url.path, endsWith('/teaching_sections'));
        expect(request.url.queryParameters['lecturer_id'], 'eq.test-user');
        return _jsonResponse(request, [
          {'code': 'LT01', 'name': 'Lập trình'},
        ]);
      });
      addTearDown(client.dispose);
      expect(
        await IncidentReportStore(client, 'test-user').teachingSections(),
        ['LT01 · Lập trình'],
      );
    },
  );

  testWidgets('giảng viên chọn đúng lớp thật khi cần hỗ trợ giờ dạy', (
    tester,
  ) async {
    await useMobileScreen(tester);
    IncidentReport? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentReportForm(
            name: 'Giảng viên',
            id: 'GV01',
            role: UserRole.teacher,
            nextReportId: () => 1,
            rooms: const {'room-id': 'Phòng thật'},
            equipment: const {},
            courseSections: const ['LT01 · Lập trình'],
            onSubmitted: (report) async {
              submitted = report;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng thật').last);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).first, 'Máy lỗi');
    await tester.enterText(find.byType(TextFormField).last, 'Không lên hình');
    await tester.ensureVisible(find.text('Cần hỗ trợ ngay trong giờ dạy'));
    await tester.tap(find.text('Cần hỗ trợ ngay trong giờ dạy'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi báo cáo'));
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(submitted, isNull);
    expect(find.text('Vui lòng chọn lớp học phần đang dạy'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.arrow_drop_down).last);
    await tester.tap(find.byIcon(Icons.arrow_drop_down).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('LT01 · Lập trình').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi báo cáo'));
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(submitted?.course, 'LT01 · Lập trình');
    expect(submitted?.assetId, 'room-id');
    expect(submitted?.needsSupport, isTrue);
    await unmountApp(tester);
  });

  test(
    'báo cáo đã duyệt vẫn open nhưng hiển thị trạng thái Đã duyệt',
    () async {
      final client = await _authenticatedClient(
        (request) async => _jsonResponse(request, [
          _row()..['approved_at'] = '2026-11-17T03:00:00Z',
        ]),
      );
      addTearDown(client.dispose);
      final saved = (await IncidentReportStore(
        client,
        'test-user',
      ).history()).single;
      expect(saved.status, IncidentStatus.approved);
    },
  );

  for (final uploadFails in [false, true]) {
    testWidgets(
      uploadFails
          ? 'ảnh tải lên lỗi không tạo báo cáo thiếu ảnh'
          : 'lưu ảnh riêng tư trước khi tạo báo cáo và đọc lại ảnh',
      (tester) async {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder)
              .drawColor(const Color(0xFF123456), ui.BlendMode.src);
          final picture = recorder.endRecording();
          final image = await picture.toImage(1, 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          image.dispose();
          picture.dispose();
          final calls = <String>[];
          final client = await _authenticatedClient((request) async {
            final path = request.url.path;
            if (path.contains('/storage/v1/')) {
              expect(path, endsWith('/incident-images/test-user/savedid.png'));
              if (request.method == 'POST') {
                calls.add('upload');
                return uploadFails
                    ? _jsonResponse(request, {
                        'statusCode': '403',
                        'error': 'Unauthorized',
                        'message': 'Denied',
                      }, 403)
                    : _jsonResponse(request, {
                        'Key': 'incident-images/test-user/savedid.png',
                      });
              }
              calls.add('download');
              return http.Response.bytes(
                bytes,
                200,
                request: request,
                headers: {'content-type': 'image/png'},
              );
            }
            if (request.method == 'POST') {
              calls.add('insert');
              expect(jsonDecode(request.body)['has_photo'], isTrue);
              return _jsonResponse(request, _row()..['has_photo'] = true, 201);
            }
            return path.endsWith('/incident_reports')
                ? _jsonResponse(request, [])
                : _jsonResponse(request, {'id': 'room-id'});
          });
          try {
            final store = IncidentReportStore(client, 'test-user');
            final submission = store.submit(
              'saved-id',
              _report(photos: [bytes]),
            );
            if (uploadFails) {
              await expectLater(submission, throwsA(isA<StorageException>()));
              expect(calls, ['upload']);
            } else {
              expect((await submission).hasPhoto, isTrue);
              expect(await store.loadPhoto('saved-id'), bytes);
              expect(calls, ['upload', 'insert', 'download']);
            }
          } finally {
            await client.dispose();
          }
        });
      },
    );
  }

  for (final equipment in [false, true]) {
    test(
      'gửi ${equipment ? 'thiết bị' : 'phòng'} bằng UUID dù tên đã đổi',
      () async {
        var writes = 0;
        final client = await _authenticatedClient((request) async {
          final query = request.url.queryParameters;
          if (request.method == 'POST') {
            writes++;
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(
              body[equipment ? 'equipment_id' : 'room_id'],
              equipment ? 'device-id' : 'room-id',
            );
            expect(
              body.containsKey(equipment ? 'room_id' : 'equipment_id'),
              isFalse,
            );
            expect(body['occurred_at'], '2026-11-17T01:00:00.000Z');
            expect(body['course_section'], 'Nhóm 02');
            expect(body['needs_support'], isTrue);
            expect(body.containsKey('reporter_id'), isFalse);
            return _jsonResponse(request, _row(equipment: equipment), 201);
          }
          if (request.url.path.endsWith('/incident_reports')) {
            return _jsonResponse(request, []);
          }
          expect(query['id'], equipment ? 'eq.device-id' : 'eq.room-id');
          expect(query.containsKey('name'), isFalse);
          expect(
            query[equipment ? 'room_id' : 'is_archived'],
            equipment ? 'is.null' : 'eq.false',
          );
          return _jsonResponse(request, {
            'id': equipment ? 'device-id' : 'room-id',
          });
        });
        addTearDown(client.dispose);
        final saved = await IncidentReportStore(
          client,
          'test-user',
        ).submit('submission-id', _report(equipment: equipment));
        expect(writes, 1);
        expect(saved.report.id, 42);
        expect(saved.report.assetId, equipment ? 'device-id' : 'room-id');
        expect(
          saved.report.asset,
          equipment ? 'Thiết bị hiện tại' : 'Tên hiện tại',
        );
      },
    );
  }

  test('gửi lại báo cáo đã lưu không ghi thêm hoặc tải ảnh lại', () async {
    final requests = <http.Request>[];
    final client = await _authenticatedClient((request) async {
      requests.add(request);
      return _jsonResponse(request, [_row()]);
    });
    addTearDown(client.dispose);
    final saved = await IncidentReportStore(
      client,
      'test-user',
    ).submit('saved-id', _report());
    expect(saved.report.id, 42);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(requests.single.url.queryParameters['reporter_id'], 'eq.test-user');
  });

  test(
    'hủy chỉ cập nhật báo cáo của tài khoản đang ở trạng thái open',
    () async {
      final client = await _authenticatedClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.queryParameters['id'], 'eq.saved-id');
        expect(request.url.queryParameters['reporter_id'], 'eq.test-user');
        expect(request.url.queryParameters['status'], 'eq.open');
        expect(jsonDecode(request.body), {'status': 'cancelled'});
        return _jsonResponse(request, _row(status: 'cancelled'));
      });
      addTearDown(client.dispose);
      expect(
        (await IncidentReportStore(client, 'test-user').cancel('saved-id'))
            .status,
        IncidentStatus.cancelled,
      );
    },
  );

  test('mất phiên chặn đọc và ghi báo cáo trước khi gọi API', () async {
    final client = SupabaseClient(
      'https://example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (_) async => throw StateError('Không được gọi API'),
      ),
    );
    addTearDown(client.dispose);
    final store = IncidentReportStore(client, 'test-user');
    await expectLater(store.assets(), throwsA(isA<AuthException>()));
    await expectLater(store.history(), throwsA(isA<AuthException>()));
    await expectLater(
      store.submit('id', _report()),
      throwsA(isA<AuthException>()),
    );
    await expectLater(store.cancel('id'), throwsA(isA<AuthException>()));
    expect(() => store.loadPhoto('id'), throwsA(isA<AuthException>()));
  });

  testWidgets('lỗi danh mục vẫn mở được lịch sử và tải lại danh mục', (
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
    final store = _RetryReportStore(client)..failAssets = true;
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(name: 'Sinh viên', id: 'SV01', incidentStore: store),
      ),
    );
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh mục. Thử lại'), findsOneWidget);
    await tester.tap(find.text('Báo cáo của tôi'));
    await tester.pumpAndSettle();
    expect(store.historyCalls, 1);
    expect(find.text('Bạn chưa gửi báo cáo sự cố nào.'), findsOneWidget);
    await tester.tap(find.text('Tạo báo cáo'));
    await tester.pumpAndSettle();
    store.failAssets = false;
    await tester.tap(find.text('Không tải được danh mục. Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(IncidentReportForm), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('tài sản trùng tên gửi đúng UUID và chặn nhấn gửi trùng', (
    tester,
  ) async {
    await useMobileScreen(tester);
    final pending = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentReportForm(
            name: 'Sinh viên',
            id: 'SV01',
            role: UserRole.student,
            nextReportId: () => 0,
            rooms: const {
              'aaaaaaaa-1': 'Phòng trùng',
              'bbbbbbbb-2': 'Phòng trùng',
            },
            equipment: const {},
            onSubmitted: (report) {
              calls++;
              expect(report.assetId, 'bbbbbbbb-2');
              expect(report.asset, 'Phòng trùng');
              return pending.future;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phòng trùng · bbbbbbbb').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Lỗi nguồn');
    await tester.enterText(find.byType(TextFormField).last, 'Không bật được');
    await tester.ensureVisible(find.text('Gửi báo cáo'));
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pump();
    expect(find.text('Đang gửi...'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 1);
    pending.completeError(Exception('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi nguồn'), findsOneWidget);
    expect(
      find.text('Không gửi được báo cáo. Vui lòng thử lại.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

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
