import 'package:flutter/material.dart';

import '../models/technician_task.dart';
import '../presentation/task_details_page.dart';

void showTaskDetails(
  BuildContext context,
  TechnicianTask task,
  VoidCallback onChanged,
) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TaskDetailsPage(task: task, onChanged: onChanged),
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
