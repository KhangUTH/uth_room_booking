import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/technician_task.dart';
import '../models/task_filter.dart';
import '../widgets/task_details.dart';
import '../widgets/technician_header.dart';

class TechnicianHomePage extends StatefulWidget {
  final String name;
  final String id;
  final List<TechnicianTask> tasks;
  final VoidCallback onChanged;

  const TechnicianHomePage({
    super.key,
    required this.name,
    required this.id,
    required this.tasks,
    required this.onChanged,
  });

  @override
  State<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  TaskFilter? _filter = TaskFilter.pending;
  int _type = 0;
  String _query = '';
  bool _urgentOnly = false;
  bool _todayOnly = false;
  bool _showExtraFilters = false;

  void _refresh() {
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tasks =
        widget.tasks
            .where(
              (task) =>
                  (_filter == null || _filter!.matches(task, now)) &&
                  (_type == 0 ||
                      (_type == 2
                          ? task.isMaintenance
                          : !task.isMaintenance)) &&
                  (!_urgentOnly || task.priority == TaskPriority.urgent) &&
                  (!_todayOnly || DateUtils.isSameDay(task.scheduledAt, now)) &&
                  '${task.title} ${task.location} ${task.description} ${task.reporter}'
                      .toLowerCase()
                      .contains(_query),
            )
            .toList()
          ..sort(
            (a, b) => _filter == TaskFilter.completed
                ? b.scheduledAt.compareTo(a.scheduledAt)
                : a.scheduledAt.compareTo(b.scheduledAt),
          );
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: TechnicianHeader(name: widget.name, id: widget.id),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final filter in TaskFilter.values)
                        SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: _stat(
                            filter,
                            widget.tasks
                                .where((t) => filter.matches(t, now))
                                .length,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Tìm công việc…',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Lọc thêm',
                      isSelected: _showExtraFilters,
                      onPressed: () => setState(
                        () => _showExtraFilters = !_showExtraFilters,
                      ),
                      icon: Icon(
                        Icons.filter_alt_outlined,
                        color: _urgentOnly || _todayOnly
                            ? AppColors.primary
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_showExtraFilters)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('Khẩn'),
                        selected: _urgentOnly,
                        onSelected: (value) =>
                            setState(() => _urgentOnly = value),
                      ),
                      FilterChip(
                        label: const Text('Hôm nay'),
                        selected: _todayOnly,
                        onSelected: (value) =>
                            setState(() => _todayOnly = value),
                      ),
                    ],
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var index = 0; index < 3; index++)
                      ChoiceChip(
                        key: ValueKey('task-type-$index'),
                        label: Text(['Mọi loại', 'Sự cố', 'Bảo trì'][index]),
                        selected: _type == index,
                        onSelected: (_) => setState(() => _type = index),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_filter?.label ?? 'Tất cả trạng thái'} · ${tasks.length} công việc',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _filter = null),
                      child: const Text('Tất cả'),
                    ),
                  ],
                ),
                if (_filter == TaskFilter.overdue) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Đã qua thời gian dự kiến và chưa hoàn tất.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (tasks.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Không có công việc phù hợp.')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => _ticket(tasks[index]),
            ),
          ),
      ],
    );
  }

  Widget _stat(TaskFilter filter, int count) {
    final selected = _filter == filter;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : const Color(0xFF5C9F9C),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('task-stat-${filter.name}'),
          onTap: () => setState(() => _filter = filter),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticket(TechnicianTask task) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTaskDetails(context, task, _refresh),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TaskBadge(
                  label: task.priority.label,
                  color: switch (task.priority) {
                    TaskPriority.urgent => Colors.red,
                    TaskPriority.medium => const Color(0xFF9A7100),
                    TaskPriority.low => const Color(0xFF25823A),
                  },
                ),
              ],
            ),
            Text(
              '${task.description} · ${task.location}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              '${task.scheduledAt.day}/${task.scheduledAt.month}/${task.scheduledAt.year} · '
              '${task.scheduledAt.hour.toString().padLeft(2, '0')}:${task.scheduledAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Wrap(
              spacing: 6,
              children: [
                Text(
                  task.isMaintenance ? 'Bảo trì' : 'Sự cố',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                if (TaskFilter.overdue.matches(task, DateTime.now()))
                  const TaskBadge(label: 'Quá hạn', color: Colors.red),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.reporter,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (task.status == TaskStatus.pending)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        task.status = TaskStatus.accepted;
                        _refresh();
                      },
                      child: const Text(
                        'Nhận việc',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                else
                  Text(
                    task.status.label,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
