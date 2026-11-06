import 'package:flutter/material.dart';

import '../models/technician_task.dart';

void showTaskDetails(
  BuildContext context,
  TechnicianTask task,
  VoidCallback onChanged,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('${task.location}\n${task.description}\n${task.reporter}'),
            const SizedBox(height: 12),
            Text('Trạng thái: ${task.status.label}'),
            Text('Mức độ: ${task.priority.label}'),
            Text(
              'Lịch: ${task.scheduledAt.day}/${task.scheduledAt.month}/${task.scheduledAt.year} '
              '${task.scheduledAt.hour.toString().padLeft(2, '0')}:${task.scheduledAt.minute.toString().padLeft(2, '0')}',
            ),
            if (task.status != TaskStatus.completed) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    task.status = switch (task.status) {
                      TaskStatus.pending => TaskStatus.accepted,
                      TaskStatus.accepted => TaskStatus.inProgress,
                      _ => TaskStatus.completed,
                    };
                    onChanged();
                    Navigator.pop(context);
                  },
                  child: Text(switch (task.status) {
                    TaskStatus.pending => 'Nhận việc',
                    TaskStatus.accepted => 'Bắt đầu xử lý',
                    _ => 'Hoàn tất công việc',
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class TaskBadge extends StatelessWidget {
  final String label;
  final Color color;
  const TaskBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}
