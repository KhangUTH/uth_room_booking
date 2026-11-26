import 'package:flutter/material.dart';

import '../models/technician_task.dart';

import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

extension TaskStatusColor on TaskStatus {
  Color get color => switch (this) {
    TaskStatus.pending => const Color(0xFF9A5E09),
    TaskStatus.inProgress => AppColors.primary,
    TaskStatus.completed => const Color(0xFF16704F),
  };
}

Future<void> showTaskDetails(
  BuildContext context,
  TechnicianTask task,
  VoidCallback onChanged,
) async {
  var changed = false;
  await Navigator.of(context).pushNamed<void>(
    AppRoute.technicianTask,
    arguments: (task: task, onChanged: () => changed = true),
  );
  if (context.mounted && changed) onChanged();
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
