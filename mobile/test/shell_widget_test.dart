import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/booking/data/asset_catalog.dart';
import 'package:uth_room_booking/features/booking/data/booking_store.dart';
import 'package:uth_room_booking/features/booking/data/sample_booking_data.dart';
import 'package:uth_room_booking/features/booking/models/booking.dart';
import 'package:uth_room_booking/features/notifications/data/notice_store.dart';
import 'package:uth_room_booking/features/notifications/presentation/notifications_view.dart';
import 'package:uth_room_booking/shared/layouts/header.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

class _ScheduleStore extends BookingStore {
  _ScheduleStore(super.client);

  int calls = 0;
  int historyCalls = 0;
  List<({String id, Booking booking})> rows = [];

  @override
  Future<List<({String id, Booking booking})>> history() async {
    historyCalls++;
    return rows;
  }

  @override
  Future<Set<BookingSlot>> busySlots(DateTime day) async {
    calls++;
    return {};
  }
}

void main() {
  test('danh mục vẫn tải phòng hợp lệ khi một phòng thiếu sức chứa', () async {
    final client = SupabaseClient(
      'https://example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          request.url.path.endsWith('/rooms')
              ? '[{"id":"missing","name":"Phòng cũ","capacity":null,"is_active":true},'
                    '{"id":"valid","name":"H509","location":"Tầng 5","capacity":32,"is_active":true}]'
              : '[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(client.dispose);
    final catalog = await loadAssetCatalog(client);
    expect(catalog.rooms.map((room) => room.id), ['valid']);
  });

  test('ca bận và yêu cầu đặt thiết bị dùng ID khi tên bị trùng', () async {
    final day = DateTime(2026, 11, 24);
    final client = SupabaseClient(
      'https://example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/mobile_busy_booking_slots')) {
          return http.Response(
            '[{"equipment_id":"first","start_time":"2026-11-24T07:00:00+07:00"}]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.url.path, endsWith('/bookings'));
        expect(request.method, 'POST');
        expect(jsonDecode(request.body)['equipment_id'], 'second');
        return http.Response('', 201, request: request);
      }),
    );
    addTearDown(client.dispose);
    final store = BookingStore(client);
    final asset = (
      id: 'second',
      name: 'Micro',
      detail: 'H509',
      capacity: 0,
      slots: List.filled(4, SlotStatus.free),
    );
    final slot = (date: day, asset: asset.bookingKey, index: 0);
    expect(await store.busySlots(day), {(date: day, asset: 'first', index: 0)});
    await store.create(slot, asset);
  });

  testWidgets('quay lại tab Lịch tự tải lại ca trống', (tester) async {
    await useMobileScreen(tester);
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    addTearDown(() => tester.runAsync(client.dispose));
    final store = _ScheduleStore(client);
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          name: 'Sinh viên kiểm thử',
          id: 'SV01',
          bookingStore: store,
          loadCatalog: () async => (
            rooms: sampleBookingRooms,
            equipment: sampleBookingEquipment,
            roomsUnavailableToTeachers: {sampleLibraryRoomName},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.calls, 0);
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(store.calls, 1);
    final historyCalls = store.historyCalls;
    await tester.tap(find.text('Thiết bị'));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách thiết bị'), findsOneWidget);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có đăng ký trong ngày này'), findsOneWidget);
    expect(store.calls, 1);
    expect(store.historyCalls, historyCalls);
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(store.calls, 2);
    final today = BookingStore.campusNow;
    final asset = sampleBookingRooms.first;
    store.rows = [
      (
        id: 'reviewed',
        booking: (
          slot: (
            date: DateTime(today.year, today.month, today.day),
            asset: asset.bookingKey,
            index: 0,
          ),
          asset: asset,
          section: null,
          studentCount: 10,
          status: BookingStatus.approved,
        ),
      ),
    ];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.text('Đã duyệt'), findsOneWidget);
    expect(store.calls, 3);
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 16));
    expect(store.calls, 3);
    await unmountApp(tester);
  });

  testWidgets('nhấn giữ, chọn tất cả và xóa thông báo đã chọn', (tester) async {
    await useMobileScreen(tester);
    List<dynamic>? removedIds;
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.com',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/rpc/delete_my_app_notifications')) {
            removedIds =
                jsonDecode(request.body)['notice_ids'] as List<dynamic>;
            return http.Response('', 204, request: request);
          }
          return http.Response(
            jsonEncode([
              for (final id in [1, 2])
                {
                  'id': id,
                  'title': 'Thông báo $id',
                  'message': 'Đơn đăng ký',
                  'created_at': '2026-11-17T00:00:00Z',
                },
            ]),
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    ))!;
    final store = NoticeStore(client);
    addTearDown(store.dispose);
    addTearDown(() => tester.runAsync(client.dispose));
    await tester.runAsync(store.refresh);
    expect(store.notices.map((notice) => notice.id), [1, 2]);
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsView(
          read: store.read,
          saved: store.saved,
          store: store,
        ),
      ),
    );

    await tester.longPress(find.text('Thông báo 1'));
    await tester.pumpAndSettle();
    expect(find.text('Đã chọn 1'), findsOneWidget);
    await tester.tap(find.text('Chọn tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Đã chọn 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa thông báo đã chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(removedIds, unorderedEquals([1, 2]));
    expect(find.text('Không có thông báo'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('kéo xuống tải lại danh mục sau khi mạng có lại', (tester) async {
    await useMobileScreen(tester);
    var connected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          name: 'Sinh viên kiểm thử',
          id: 'SV01',
          loadCatalog: () async {
            if (!connected) throw StateError('Offline');
            return (
              rooms: sampleBookingRooms,
              equipment: sampleBookingEquipment,
              roomsUnavailableToTeachers: {sampleLibraryRoomName},
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh mục. Thử lại'), findsOneWidget);

    connected = true;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách phòng'), findsOneWidget);
    expect(find.text('Không tải được danh mục. Thử lại'), findsNothing);
  });

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
