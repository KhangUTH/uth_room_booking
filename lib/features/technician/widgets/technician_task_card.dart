import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_sizes.dart';
import '../models/technician_task.dart';
import '../models/task_filter.dart';
import 'task_details.dart';

class TechnicianTaskCard extends StatelessWidget {
  const TechnicianTaskCard({
    super.key,
    required this.task,
    required this.now,
    required this.onChanged,
  });

  final TechnicianTask task;
  final DateTime now;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = task.status.color;
    final urgent = TaskFilter.urgent.matches(task);
    final action = switch (task.status) {
      TaskStatus.pending => 'Nhận việc',
      TaskStatus.inProgress => 'Hoàn tất',
      TaskStatus.completed => null,
    };
    final localizations = MaterialLocalizations.of(context);
    final deadline = task.scheduledAt;
    final time = deadline == null
        ? null
        : localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(deadline),
            alwaysUse24HourFormat: true,
          );
    final day = deadline == null || DateUtils.isSameDay(now, deadline)
        ? 'hôm nay'
        : localizations.formatShortDate(deadline);
    final overdue =
        task.status != TaskStatus.completed &&
        (deadline?.isBefore(now) ?? false);
    final timeColor = overdue ? const Color(0xFFAE251A) : AppColors.textMuted;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: .45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 4,
            child: ColoredBox(color: statusColor),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.isMaintenance
                        ? Icons.apartment_outlined
                        : Icons.devices_other_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: AppTextSizes.action,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (urgent) ...[
                            const SizedBox(width: 5),
                            const TaskBadge(
                              label: 'Gấp',
                              color: Color(0xFFAE251A),
                            ),
                          ],
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TaskBadge(
                            label: task.isMaintenance ? 'Bảo trì' : 'Sự cố',
                            color: AppColors.textMuted,
                          ),
                          Text(
                            task.location,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          TaskBadge(
                            label: task.status.label,
                            color: statusColor,
                          ),
                        ],
                      ),
                      Text(
                        task.description,
                        style: const TextStyle(fontSize: AppTextSizes.item),
                      ),
                      if (time != null)
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: timeColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Trước $time $day',
                                style: TextStyle(
                                  color: timeColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        spacing: 8,
                        children: [
                          if (action != null)
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                onPressed: () {
                                  if (task.advance()) onChanged();
                                },
                                child: Text(
                                  action,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          Flexible(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              onPressed: () =>
                                  showTaskDetails(context, task, onChanged),
                              child: const Text(
                                'Chi tiết',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
