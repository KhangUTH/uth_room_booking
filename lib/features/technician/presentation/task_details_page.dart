import 'package:flutter/material.dart';

import '../models/technician_task.dart';

class TaskDetailsPage extends StatefulWidget {
  final TechnicianTask task;
  final VoidCallback onChanged;

  const TaskDetailsPage({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  TechnicianTask get task => widget.task;

  void _advance(BuildContext context) {
    task.status = switch (task.status) {
      TaskStatus.pending => TaskStatus.accepted,
      TaskStatus.accepted => TaskStatus.inProgress,
      _ => TaskStatus.completed,
    };
    widget.onChanged();
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Đã cập nhật: ${task.status.label}')),
      );
  }

  void _openImage(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Ảnh minh chứng'),
          ),
          body: SafeArea(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  task.evidence!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'Không thể hiển thị ảnh minh chứng.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledAt = task.scheduledAt;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(task.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Vị trí: ${task.location}'),
              const SizedBox(height: 8),
              Text('Người báo cáo: ${task.reporter}'),
              const SizedBox(height: 8),
              Text('Trạng thái: ${task.status.label}'),
              const SizedBox(height: 8),
              Text('Mức độ: ${task.priority.label}'),
              const SizedBox(height: 8),
              Text(
                'Lịch: ${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} '
                '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 24),
              Text(
                'Mô tả sự cố',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(task.description),
              const SizedBox(height: 24),
              Text(
                'Hình ảnh minh chứng',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (task.evidence != null) ...[
                Semantics(
                  button: true,
                  label: 'Xem ảnh minh chứng toàn màn hình',
                  child: InkWell(
                    onTap: () => _openImage(context),
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        task.evidence!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Không thể hiển thị ảnh minh chứng.'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Chạm vào ảnh để xem toàn màn hình và phóng to.'),
              ] else
                const Text('Không có ảnh minh chứng được đính kèm.'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: task.status == TaskStatus.completed
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _advance(context),
                    child: Text(switch (task.status) {
                      TaskStatus.pending => 'Nhận việc',
                      TaskStatus.accepted => 'Bắt đầu xử lý',
                      _ => 'Hoàn tất công việc',
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}
