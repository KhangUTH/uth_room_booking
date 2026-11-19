import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/technician/data/technician_work_store.dart';
import 'package:uth_room_booking/features/technician/models/technician_task.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

Map<String, dynamic> _job({String status = 'open'}) => {
  'id': 'incident-id',
  'approved_at': '2026-11-17T01:00:00Z',
  'assigned_to': 'technician-id',
  'status': status,
  'title': 'Tai nghe bị hỏng',
  'description': 'Không nghe được',
  'asset_name': 'Tai nghe Logitech H340',
  'reporter_name': 'Sinh viên',
  'needs_support': true,
  'has_photo': false,
  'status_updated_at': '2026-11-17T02:00:00Z',
};

Future<SupabaseClient> _client(
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
          id: 'technician-id',
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

http.Response _json(http.Request request, Object value, [int status = 200]) =>
    http.Response(
      jsonEncode(value),
      status,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class _WorkStore extends TechnicianWorkStore {
  _WorkStore(super.client, super.userId);
  int calls = 0;
  bool fail = false;
  @override
  Future<List<TechnicianTask>> load() async {
    calls++;
    if (fail) throw StateError('Offline');
    return [
      TechnicianTask(
        title: 'Công việc đã duyệt',
        location: 'Phòng thật',
        description: 'Lỗi thật',
        reporter: 'SV',
        scheduledAt: null,
      ),
    ];
  }
}

void main() {
  test('trả lại công việc qua RPC và chặn thao tác trên việc đã trả', () async {
    final client = await _client((request) async {
      if (request.url.path.endsWith('/technician_incident_jobs')) {
        return _json(request, [_job(status: 'in_progress')]);
      }
      expect(request.url.path, endsWith('/release_technician_incident'));
      expect(jsonDecode(request.body), {'report_id': 'incident-id'});
      return _json(request, _job()..['assigned_to'] = null);
    });
    addTearDown(client.dispose);
    final task = (await TechnicianWorkStore(
      client,
      'technician-id',
    ).load()).single;
    expect(await task.release(), isTrue);
    expect(await task.release(), isFalse);
    expect(await task.advanceSaved(), isFalse);
  });
  test('chỉ đọc công việc được duyệt và giao đúng tài khoản; trạng thái lưu qua RPC', () async {
    final transitions = <String>[];
    final client = await _client((request) async {
      if (request.url.path.endsWith('/technician_incident_jobs')) {
        return _json(request, [
          _job()..['assigned_to'] = null,
          _job()..['approved_at'] = null,
          _job()..['assigned_to'] = 'other-tech',
        ]);
      }
      expect(request.url.path, endsWith('/advance_technician_incident'));
      final body = jsonDecode(request.body);
      expect(body['report_id'], 'incident-id');
      transitions.add(body['expected_status'] as String);
      return _json(
        request,
        _job(status: transitions.length == 1 ? 'in_progress' : 'resolved'),
      );
    });
    addTearDown(client.dispose);
    final jobs = await TechnicianWorkStore(client, 'technician-id').load();
    expect(jobs, hasLength(1));
    final task = jobs.single;
    expect(task.location, 'Tai nghe Logitech H340');
    expect(task.isUrgent, isTrue);
    expect(task.advance(), isFalse);
    expect(await task.advanceSaved(), isTrue);
    expect(task.status, TaskStatus.inProgress);
    expect(await task.advanceSaved(), isTrue);
    expect(task.status, TaskStatus.completed);
    expect(await task.advanceSaved(), isFalse);
    expect(transitions, ['open', 'in_progress']);
  });

  test('chặn thao tác trùng và giữ trạng thái khi backend từ chối', () async {
    final response = Completer<SavedTaskProgress>();
    var writes = 0;
    final task = TechnicianTask(
      title: 'Lỗi',
      location: 'Phòng',
      description: '',
      reporter: 'SV',
      scheduledAt: null,
      saveProgress: (expected) {
        writes++;
        return response.future;
      },
    );
    final saving = task.advanceSaved();
    expect(task.saving, isTrue);
    expect(task.status, TaskStatus.pending);
    expect(await task.advanceSaved(), isFalse);
    response.completeError(Exception('Rejected'));
    await expectLater(saving, throwsException);
    expect(writes, 1);
    expect(task.saving, isFalse);
    expect(task.status, TaskStatus.pending);
    task.dispose();
  });

  test('lỗi quyền cập nhật không đổi trạng thái trên app', () async {
    final client = await _client(
      (request) async => request.url.path.endsWith('/technician_incident_jobs')
          ? _json(request, [_job()])
          : _json(request, {'code': '42501', 'message': 'Forbidden'}, 403),
    );
    addTearDown(client.dispose);
    final task = (await TechnicianWorkStore(
      client,
      'technician-id',
    ).load()).single;
    await expectLater(task.advanceSaved(), throwsA(isA<PostgrestException>()));
    expect(task.status, TaskStatus.pending);
    expect(task.saving, isFalse);
  });

  testWidgets(
    'tài khoản kỹ thuật dùng công việc thật, không trộn việc mẫu; tải lại sau lỗi',
    (tester) async {
      await useMobileScreen(tester);
      final client = (await tester.runAsync(
        () => _client((request) async => _json(request, [])),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      final store = _WorkStore(client, 'technician-id')..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            name: 'Kỹ thuật viên',
            id: 'KT01',
            role: UserRole.technician,
            workStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được công việc đã duyệt. Thử lại'),
        findsOneWidget,
      );
      store.fail = false;
      await tester.tap(find.text('Không tải được công việc đã duyệt. Thử lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công việc'));
      await tester.pumpAndSettle();
      expect(find.text('Công việc đã duyệt'), findsOneWidget);
      expect(find.text('Máy chiếu - H203'), findsNothing);
      expect(store.calls, greaterThanOrEqualTo(2));
      await unmountApp(tester);
    },
  );
}
