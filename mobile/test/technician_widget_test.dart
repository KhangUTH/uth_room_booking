import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uth_room_booking/core/router/app_router.dart';
import 'package:uth_room_booking/features/auth/models/user_role.dart';
import 'package:uth_room_booking/features/booking/data/asset_catalog.dart';
import 'package:uth_room_booking/features/technician/data/maintenance_proposal_store.dart';
import 'package:uth_room_booking/features/technician/models/maintenance_proposal.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_work_view.dart';
import 'package:uth_room_booking/features/technician/widgets/technician_task_card.dart';
import 'package:uth_room_booking/shared/layouts/main_shell.dart';

import 'support/widget_test_helpers.dart';

void main() {
  test('đề xuất dùng ID của thiết bị đã chọn khi tên trùng nhau', () async {
    var inserts = 0;
    final client = SupabaseClient(
      'https://example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final Object response;
        switch (request.url.pathSegments.last) {
          case 'rooms':
            expect(request.method, 'GET');
            response = [];
          case 'equipment':
            expect(request.method, 'GET');
            response = [
              {'id': 'first', 'name': 'Micro', 'location': 'H003'},
              {'id': 'second', 'name': 'Micro', 'location': 'H509'},
            ];
          case 'maintenance_proposals':
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {
              'equipment_id': 'second',
              'reason': 'Mất tiếng',
            });
            inserts++;
            response = {
              'id': 'proposal',
              'equipment_id': 'second',
              'reason': 'Mất tiếng',
              'status': 'pending',
              'equipment': {'name': 'Micro', 'location': 'H509'},
            };
          default:
            fail('Yêu cầu không mong đợi: ${request.url.path}');
        }
        return http.Response(
          jsonEncode(response),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final catalog = await loadAssetCatalog(client);
    final saved = await MaintenanceProposalStore(client).submit(
      MaintenanceProposal(asset: catalog.equipment.last, reason: 'Mất tiếng'),
    );
    expect(saved.asset.id, 'second');
    expect(inserts, 1);
  });

  testWidgets('phân biệt danh sách đang tải và danh sách trống', (
    tester,
  ) async {
    Future<void> showJobs({required bool loading}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnicianWorkView(
            jobs: const [],
            filter: null,
            loading: loading,
            onFilter: (_) {},
            onChanged: () {},
          ),
        ),
      ),
    );
    final emptyMessage = find.text('Không có công việc trong mục này');
    await showJobs(loading: true);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(emptyMessage, findsNothing);
    await showJobs(loading: false);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(emptyMessage, findsOneWidget);
  });

  testWidgets('kỹ thuật viên dùng thanh dưới riêng và tiếp nhận sự cố', (
    tester,
  ) async {
    await useMobileScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(
          name: 'Trần Minh Khoa',
          id: 'KT-0217',
          role: UserRole.technician,
        ),
      ),
    );
    final navigation = find.byType(BottomNavigationBar);
    expect(
      tester
          .widget<BottomNavigationBar>(navigation)
          .items
          .map((item) => item.label),
      ['Trang chủ', 'Công việc', 'Cá nhân'],
    );
    await tester.tap(find.text('Phòng, thiết bị'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng và thiết bị phụ trách'), findsOneWidget);
    expect(find.text('Hoạt động · 7'), findsOneWidget);
    expect(find.text('Bảo trì · 2'), findsOneWidget);
    expect(find.text('Có sự cố'), findsNothing);
    expect(tester.widget<BottomNavigationBar>(navigation).currentIndex, 0);
    await tester.tap(find.text('Phòng B2-304'));
    await tester.pumpAndSettle();
    expect(find.text('Lý do bảo trì'), findsOneWidget);
    expect(find.text('Phòng B2-304'), findsWidgets);
    await tester.enterText(
      find.byType(TextFormField),
      'Chuột hỏng, kho hết hàng thay thế',
    );
    expect(find.text('Thời gian dự kiến (tùy chọn)'), findsNothing);
    await tester.ensureVisible(find.text('Gửi đề xuất'));
    await tester.tap(find.text('Gửi đề xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chuột hỏng, kho hết hàng thay thế'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsNothing);
    await tester.tap(find.text('Chuột hỏng, kho hết hàng thay thế'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết đề xuất'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Chờ duyệt'), findsOneWidget);
    await tester.tap(find.text('Hủy đề xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(tester.widget<BottomNavigationBar>(navigation).currentIndex, 0);
    await tester.tap(find.text('Thiết bị'));
    await tester.pumpAndSettle();
    expect(find.text('Chuột hỏng, kho hết hàng thay thế'), findsNothing);
    expect(find.text('Từ chối'), findsOneWidget);
    await tester.tap(find.text('Tạo đề xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn thiết bị'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Chọn thiết bị'), findsNothing);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Phòng và thiết bị phụ trách'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp nhận sự cố'));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(navigation).currentIndex, 1);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(TechnicianTaskCard, 'Máy chiếu - H203'),
        matching: find.text('Chi tiết'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết công việc'), findsOneWidget);
    await tester.tap(find.text('Nhận việc'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết công việc'), findsNothing);
    expect(tester.widget<BottomNavigationBar>(navigation).currentIndex, 1);
    expect(find.text('Máy chiếu - H203'), findsNothing);

    await tester.tap(find.text('Đang xử lý').first);
    await tester.pumpAndSettle();
    final details = find.descendant(
      of: find.widgetWithText(TechnicianTaskCard, 'Máy chiếu - H203'),
      matching: find.text('Chi tiết'),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.scrollUntilVisible(details.hitTestable(), 180);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Đang xử lý'), findsOneWidget);
    await tester.tap(find.text('Hoàn tất công việc'));
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Đã hoàn tất'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Máy chiếu - H203'), findsNothing);

    await tester.scrollUntilVisible(
      find.byIcon(Icons.local_fire_department_outlined),
      -180,
    );
    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Máy chiếu - H302'), findsOneWidget);
    expect(find.text('Máy chiếu - H203'), findsNothing);

    await tester.tap(find.text('Hoàn tất').first);
    await tester.pumpAndSettle();
    expect(find.text('Máy chiếu - H203'), findsOneWidget);

    expect(find.text('Lịch sử dụng'), findsNothing);
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Sự cố mới cần tiếp nhận'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(navigation).currentIndex, 1);
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('MSNV: KT-0217'), findsOneWidget);
    expect(find.text('Mã nhân viên'), findsOneWidget);
    expect(find.text('Khoa'), findsNothing);
  });
}
