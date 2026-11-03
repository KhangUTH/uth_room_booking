import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:uth_room_booking/features/splash/presentation/splash_screen.dart';
import 'package:uth_room_booking/homepage.dart';
import 'package:uth_room_booking/main.dart';

void main() {
  testWidgets('application starts on the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('home page displays navigation and changes tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('Tên: Trương Minh Khang'), findsOneWidget);
    expect(find.text('Mssv: 077205002739'), findsOneWidget);
    expect(find.text('Đang ở tab 0'), findsOneWidget);

    await tester.tap(find.text('Lịch'));
    await tester.pump();

    expect(find.text('Đang ở tab 1'), findsOneWidget);
  });
}
