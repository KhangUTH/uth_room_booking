import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_room_booking/features/technician/models/technician_task.dart';
import 'package:uth_room_booking/features/technician/widgets/task_details.dart';
import 'package:uth_room_booking/features/technician/presentation/task_details_page.dart';

void main() {
  testWidgets('chi tiết KTV hiển thị ảnh minh chứng từ báo cáo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bytes = await rootBundle.load(
      'assets/images/illustrations/login_student.png',
    );
    final task = TechnicianTask(
      title: 'Thiết bị hỏng',
      location: 'A101',
      description: 'Không hoạt động',
      reporter: 'Sinh viên',
      scheduledAt: DateTime(2026, 11, 8),
      priority: TaskPriority.medium,
      evidence: bytes.buffer.asUint8List(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskDetails(context, task, () {}),
              child: const Text('Chi tiết'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Chi tiết'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        MemoryImage(task.evidence!),
        tester.element(find.byType(TaskDetailsPage)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsPage), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsPage), findsOneWidget);
    expect(find.text('Không có ảnh minh chứng được đính kèm.'), findsNothing);
    expect(find.text('Không thể hiển thị ảnh minh chứng.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'trang chi tiết mở toàn màn hình, cập nhật trạng thái và quay lại',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final task = createSampleTechnicianTasks().first;
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showTaskDetails(context, task, () => changes++),
                child: const Text('Chi tiết'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Chi tiết'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không có ảnh minh chứng được đính kèm.'),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsNothing);
      final activeSize = tester.getSize(find.byType(TaskDetailsPage));
      expect(activeSize, const Size(320, 800));
      await tester.tap(find.text('Hoàn tất công việc'));
      await tester.pumpAndSettle();

      expect(task.status, TaskStatus.completed);
      expect(changes, 1);
      expect(find.byType(TaskDetailsPage), findsOneWidget);
      expect(tester.getSize(find.byType(TaskDetailsPage)), activeSize);
      expect(activeSize.width, 320);
      expect(find.text('Trạng thái: Đã xong'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailsPage), findsNothing);
      expect(changes, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
