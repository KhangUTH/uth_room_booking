import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Màn hình điện thoại giả lập, đủ cao để không phải cuộn trong test.
Future<void> useMobileScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Gỡ toàn bộ widget để dispose AnimationController / Timer còn sót.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}
