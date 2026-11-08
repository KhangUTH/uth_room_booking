import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/shared/layouts/header.dart';
import 'package:uth_room_booking/features/technician/presentation/technician_page.dart';
import 'package:uth_room_booking/theme/app_theme.dart';

void main() {
  testWidgets('chuyển lịch KTV không tràn bố cục', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TechnicianPage(name: 'An', id: 'KTV01'),
      ),
    );
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
  });
  testWidgets('header giữ cùng kích thước trong appBar và body với tai thỏ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: 32);
    addTearDown(tester.view.reset);

    const header = MyHeader(name: 'Nguyễn An', id: 'SV01');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: header)));
    final appBarSize = tester.getSize(find.byType(MyHeader));
    final appBarAvatar = tester.getTopLeft(find.byType(CircleAvatar).first);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Column(children: [header])),
      ),
    );
    expect(tester.getSize(find.byType(MyHeader)), appBarSize);
    expect(tester.getTopLeft(find.byType(CircleAvatar).first), appBarAvatar);
    expect(appBarSize.height, MyHeader.baseHeight + 32);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header KTV có tiêu đề, biểu tượng và nút quay lại không tràn', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MyHeader(
            name: 'Kỹ thuật viên có họ tên rất dài',
            id: 'KTV01',
            isTechnician: true,
            showBackButton: true,
            title: 'LỊCH\nCÔNG VIỆC',
            titleIcon: Icons.calendar_month,
            subtitle: 'Phòng/thiết bị được phân công',
          ),
        ),
      ),
    );
    expect(find.text('Mã KTV: KTV01'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byTooltip('Thông báo'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Thông báo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
