import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/technician_task.dart';
import '../widgets/task_details.dart';
import '../widgets/technician_header.dart';

class TechnicianHomePage extends StatefulWidget {
  final String name;
  final String id;
  final List<TechnicianTask> tasks;
  final VoidCallback onChanged;
  final bool incidentsOnly;

  const TechnicianHomePage({
    super.key,
    required this.name,
    required this.id,
    required this.tasks,
    required this.onChanged,
    this.incidentsOnly = false,
  });

  @override
  State<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  String _query = '';
  bool _urgentOnly = false;
  bool _todayOnly = false;
  bool _maintenanceOnly = false;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pending = widget.tasks.where((t) => t.status == TaskStatus.pending);
    final filtered = widget.tasks.where((t) {
      final matchesType = widget.incidentsOnly
          ? !t.isMaintenance
          : t.status == TaskStatus.pending;
      return matchesType &&
          (!_urgentOnly || t.priority == TaskPriority.urgent) &&
          (!_todayOnly || DateUtils.isSameDay(t.scheduledAt, now)) &&
          (!_maintenanceOnly || t.isMaintenance) &&
          '${t.title} ${t.location} ${t.description}'.toLowerCase().contains(
            _query.toLowerCase(),
          );
    }).toList();
    final visible = _showAll ? filtered : filtered.take(3).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          TechnicianHeader(
            name: widget.name,
            id: widget.id,
            title: widget.incidentsOnly ? 'Phiếu sự cố' : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!widget.incidentsOnly) ...[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _stat('Chờ nhận', pending.length),
                      _stat(
                        'Đang sửa',
                        widget.tasks
                            .where(
                              (t) =>
                                  t.status == TaskStatus.accepted ||
                                  t.status == TaskStatus.inProgress,
                            )
                            .length,
                      ),
                      _stat(
                        'Đã xong',
                        widget.tasks
                            .where((t) => t.status == TaskStatus.completed)
                            .length,
                      ),
                      _stat(
                        'Quá hạn',
                        widget.tasks
                            .where(
                              (t) =>
                                  t.status != TaskStatus.completed &&
                                  t.scheduledAt.isBefore(now),
                            )
                            .length,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm phiếu/phòng/thiết bị',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    if (!widget.incidentsOnly)
                      IconButton(
                        tooltip: 'Chỉ hiện bảo trì',
                        isSelected: _maintenanceOnly,
                        onPressed: () => setState(
                          () => _maintenanceOnly = !_maintenanceOnly,
                        ),
                        icon: const Icon(Icons.filter_alt_outlined),
                        selectedIcon: const Icon(
                          Icons.filter_alt,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected:
                            !_urgentOnly && !_todayOnly && !_maintenanceOnly,
                        onSelected: (_) => setState(() {
                          _urgentOnly = false;
                          _todayOnly = false;
                          _maintenanceOnly = false;
                        }),
                      ),
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
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDEC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.incidentsOnly
                                  ? 'Danh sách sự cố'
                                  : 'Phiếu cần xử lý',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _showAll = !_showAll),
                            child: Text(_showAll ? 'Thu gọn' : 'Xem tất cả'),
                          ),
                        ],
                      ),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Không có phiếu phù hợp.'),
                        ),
                      for (final task in visible) _ticket(task),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, int count) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF5C9F9C),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _ticket(TechnicianTask task) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTaskDetails(context, task, widget.onChanged),
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
                        widget.onChanged();
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
