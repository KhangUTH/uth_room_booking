import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';
import '../models/technician_task.dart';
import 'technician_panel.dart';

class TechnicianAttentionCard extends StatelessWidget {
  const TechnicianAttentionCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  final TechnicianTask job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TechnicianPanel(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: job.isUrgent
            ? const Color(0xFFFBE8E6)
            : const Color(0xFFFFF0D4),
        foregroundColor: job.isUrgent
            ? const Color(0xFFB33A30)
            : const Color(0xFF835600),
        child: Icon(
          job.isUrgent
              ? Icons.local_fire_department_outlined
              : Icons.desktop_windows_outlined,
        ),
      ),
      title: Text(
        job.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppTextSizes.item,
        ),
      ),
      subtitle: Text(
        '${job.location} · ${job.status.label}',
        style: const TextStyle(fontSize: AppTextSizes.caption),
      ),
      trailing: job.isUrgent
          ? const Text(
              'Khẩn',
              style: TextStyle(
                color: Color(0xFFB33A30),
                fontSize: AppTextSizes.badge,
              ),
            )
          : null,
      onTap: onTap,
    ),
  );
}
