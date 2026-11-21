import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_sizes.dart';
import '../models/technician_task.dart';
import '../models/task_filter.dart';
import 'task_details.dart';
import 'technician_panel.dart';

class TechnicianTaskOverview extends StatelessWidget {
  const TechnicianTaskOverview({super.key, required this.task});

  final TechnicianTask task;

  @override
  Widget build(BuildContext context) {
    final scheduledAt = task.scheduledAt;
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        TechnicianPanel(
          featured: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 12,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.location_on_outlined),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      const Text(
                        'Vị trí cần xử lý',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        task.location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTextSizes.metric,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        TechnicianPanel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: AppTextSizes.metric,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TaskBadge(
                      label: 'Trạng thái: ${task.status.label}',
                      color: task.status.color,
                    ),
                    if (TaskFilter.urgent.matches(task))
                      const TaskBadge(label: 'Gấp', color: Color(0xFFAE251A)),
                  ],
                ),
                const Divider(height: 1, color: AppColors.border),
                _TaskMetadata(
                  icon: Icons.person_outline,
                  label: 'Người báo cáo',
                  value: task.reporter,
                ),
                if (scheduledAt != null)
                  _TaskMetadata(
                    icon: Icons.schedule_outlined,
                    label: 'Lịch',
                    value:
                        '${localizations.formatCompactDate(scheduledAt)} · '
                        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt), alwaysUse24HourFormat: true)}',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskMetadata extends StatelessWidget {
  const _TaskMetadata({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}
