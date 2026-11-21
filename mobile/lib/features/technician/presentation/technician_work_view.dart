import 'package:flutter/material.dart';

import '../widgets/technician_page_title.dart';

import '../../../theme/app_colors.dart';
import '../models/task_filter.dart';
import '../models/technician_task.dart';
import '../widgets/technician_task_card.dart';

class TechnicianWorkView extends StatelessWidget {
  const TechnicianWorkView({
    super.key,
    required this.jobs,
    required this.filter,
    required this.onFilter,
    required this.onChanged,
    required this.onSchedule,
    this.loading = false,
    this.onRefresh,
    this.onRetry,
  });

  final List<TechnicianTask> jobs;
  final TaskFilter? filter;
  final ValueChanged<TaskFilter?> onFilter;
  final VoidCallback onChanged;
  final VoidCallback onSchedule;
  final bool loading;
  final RefreshCallback? onRefresh;
  final VoidCallback? onRetry;

  Iterable<TechnicianTask> get urgentJobs =>
      jobs.where(TaskFilter.urgent.matches);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final matchingJobs = jobs.where((task) => filter?.matches(task) ?? true);
    final datedJobs = filter == null
        ? (matchingJobs.where((task) => task.createdAt != null).toList()..sort(
            (first, second) => second.createdAt!.compareTo(first.createdAt!),
          ))
        : const <TechnicianTask>[];
    final remaining = filter == null
        ? matchingJobs.where((task) => task.createdAt == null)
        : matchingJobs;
    final visible = [
      ...datedJobs,
      ...remaining.where(TaskFilter.urgent.matches),
      ...remaining.where((task) => !TaskFilter.urgent.matches(task)),
    ];
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(child: TechnicianPageTitle('Công việc kỹ thuật')),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onSchedule,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE0F0F0),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 15),
              label: const Text('Lịch sử dụng'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildFilters(),
        const SizedBox(height: 10),
        if (loading)
          const LinearProgressIndicator()
        else if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Không tải được công việc. Thử lại'),
          )
        else if (visible.isEmpty)
          const Center(child: Text('Không có công việc trong mục này')),
        for (final task in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TechnicianTaskCard(
              task: task,
              now: now,
              onChanged: onChanged,
            ),
          ),
      ],
    );
    final refresh = onRefresh;
    return refresh == null
        ? list
        : RefreshIndicator(onRefresh: refresh, child: list);
  }

  Widget _buildFilters() => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (urgentJobs.isNotEmpty)
            Expanded(
              child: _buildFilter(TaskFilter.urgent, 'Gấp', showCount: true),
            ),
          Expanded(child: _buildFilter(null, 'Tất cả')),
          Expanded(
            child: _buildFilter(TaskFilter.pending, 'Cần làm', showCount: true),
          ),
          Expanded(child: _buildFilter(TaskFilter.active, 'Đang xử lý')),
          Expanded(child: _buildFilter(TaskFilter.completed, 'Hoàn tất')),
        ],
      ),
    ),
  );

  Widget _buildFilter(
    TaskFilter? option,
    String label, {
    bool showCount = false,
  }) {
    final selected = option == filter;
    final urgent = option == TaskFilter.urgent;
    const urgentColor = Color(0xFFC12820);
    final color = urgent
        ? urgentColor
        : selected
        ? AppColors.primary
        : AppColors.textMuted;
    final count = showCount && option != null
        ? jobs.where(option.matches).length
        : null;
    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: () => onFilter(option),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            child: Center(
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (urgent)
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 14,
                      color: urgentColor,
                    ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (count != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: urgent
                            ? const Color(0xFFFCE8E6)
                            : const Color(0xFFE0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
