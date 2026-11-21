import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';

import '../models/task_filter.dart';
import '../models/technician_task.dart';
import '../widgets/technician_panel.dart';
import '../widgets/technician_attention_card.dart';
import '../../notifications/data/sample_notices.dart';
import '../../notifications/models/app_notice.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _pale = Color(0xFFE1F0F0);
const _line = Color(0xFFDCE8E9);
const _muted = Color(0xFF526E74);

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({
    super.key,
    required this.jobs,
    required this.onWork,
    required this.onNotifications,
    required this.onAssets,
    required this.onMaintenance,
    this.notices,
  });

  final List<TechnicianTask> jobs;
  final ValueChanged<TaskFilter?> onWork;
  final VoidCallback onNotifications;
  final VoidCallback onAssets;
  final VoidCallback onMaintenance;
  final List<AppNotice>? notices;

  int _count(TaskFilter filter) => jobs.where(filter.matches).length;

  @override
  Widget build(BuildContext context) {
    final latestNotice = notices == null
        ? technicianNotices.last
        : notices!.firstOrNull;
    final attention = jobs
        .where((job) => job.status != TaskStatus.completed)
        .take(2);
    return SingleChildScrollView(
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.appBar,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TechnicianPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 6,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          for (final status in const [
                            TaskFilter.pending,
                            TaskFilter.active,
                            TaskFilter.completed,
                          ]) ...[
                            if (status != TaskFilter.pending)
                              const VerticalDivider(width: 1, color: _line),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${_count(status)}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppTextSizes.metric,
                                    ),
                                  ),
                                  Text(
                                    status == TaskFilter.completed
                                        ? 'Hoàn thành'
                                        : status.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: AppTextSizes.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Hôm nay bạn cần làm gì?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTextSizes.section,
                  ),
                ),
                const SizedBox(height: 10),
                _actionRow(
                  _Shortcut(
                    Icons.warning_amber_outlined,
                    'Tiếp nhận sự cố',
                    '${_count(TaskFilter.pending)} sự cố đang chờ',
                    () => onWork(TaskFilter.pending),
                    featured: true,
                  ),
                  _Shortcut(
                    Icons.build_outlined,
                    'Công việc của tôi',
                    '${_count(TaskFilter.active)} việc đang xử lý',
                    () => onWork(TaskFilter.active),
                  ),
                ),
                const SizedBox(height: 12),
                _actionRow(
                  _Shortcut(
                    Icons.apartment_outlined,
                    'Phòng, thiết bị',
                    'Tài sản phụ trách',
                    onAssets,
                  ),
                  _Shortcut(
                    Icons.post_add,
                    'Đề xuất bảo trì',
                    'Tạo và xem đề xuất',
                    onMaintenance,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Việc cần chú ý',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTextSizes.section,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onWork(null),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                for (final job in attention)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TechnicianAttentionCard(
                      job: job,
                      onTap: () => onWork(
                        job.status == TaskStatus.pending
                            ? TaskFilter.pending
                            : TaskFilter.active,
                      ),
                    ),
                  ),
                if (latestNotice != null)
                  TechnicianPanel(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _pale,
                        foregroundColor: AppColors.primary,
                        child: Icon(latestNotice.icon),
                      ),
                      title: Text(
                        latestNotice.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTextSizes.item,
                        ),
                      ),
                      subtitle: Text(
                        latestNotice.message,
                        style: const TextStyle(fontSize: AppTextSizes.caption),
                      ),
                      onTap: onNotifications,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(Widget first, Widget second) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(
    this.icon,
    this.title,
    this.subtitle,
    this.onTap, {
    this.featured = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) => TechnicianPanel(
    featured: featured,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: featured ? Colors.white24 : _pale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  size: 21,
                  color: featured ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: AppTextSizes.action,
                fontWeight: FontWeight.bold,
                color: featured ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppTextSizes.caption,
                color: featured ? Colors.white : _muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
