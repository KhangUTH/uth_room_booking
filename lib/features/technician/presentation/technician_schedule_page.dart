import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/technician_task.dart';
import '../widgets/task_details.dart';
import '../widgets/technician_header.dart';

class TechnicianSchedulePage extends StatefulWidget {
  final String name;
  final String id;
  final List<TechnicianTask> tasks;
  final VoidCallback onChanged;

  const TechnicianSchedulePage({
    super.key,
    required this.name,
    required this.id,
    required this.tasks,
    required this.onChanged,
  });

  @override
  State<TechnicianSchedulePage> createState() => _TechnicianSchedulePageState();
}

class _TechnicianSchedulePageState extends State<TechnicianSchedulePage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  int _filter = 0;
  bool _unfinishedOnly = false;

  @override
  Widget build(BuildContext context) {
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final tasks = widget.tasks.where((t) {
      if (t.status == TaskStatus.pending) return false;
      if (_unfinishedOnly && t.status == TaskStatus.completed) return false;
      return _filter == 1
          ? t.status != TaskStatus.completed &&
                t.scheduledAt.isAfter(DateTime.now())
          : DateUtils.isSameDay(t.scheduledAt, _selectedDate);
    }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return SingleChildScrollView(
      child: Column(
        children: [
          TechnicianHeader(
            name: widget.name,
            id: widget.id,
            title: 'Lịch công việc',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tháng ${_selectedDate.month}, ${_selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _selectedDate = DateUtils.dateOnly(DateTime.now());
                        _filter = 0;
                      }),
                      icon: const Icon(Icons.today, size: 16),
                      label: const Text('Hôm nay'),
                    ),
                    IconButton(
                      tooltip: 'Chọn ngày',
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _selectedDate = picked;
                            _filter = 0;
                          });
                        }
                      },
                      icon: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(7, (index) {
                    final day = monday.add(Duration(days: index));
                    final selected = DateUtils.isSameDay(day, _selectedDate);
                    final hasTasks = widget.tasks.any(
                      (t) =>
                          t.status != TaskStatus.pending &&
                          DateUtils.isSameDay(t.scheduledAt, day),
                    );
                    final color = selected ? Colors.white : AppColors.primary;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 6 ? 0 : 5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() {
                            _selectedDate = day;
                            _filter = 0;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  index == 6 ? 'CN' : 'T${index + 2}',
                                  style: TextStyle(fontSize: 11, color: color),
                                ),
                                Text(
                                  '${day.day}'.padLeft(2, '0'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                  child: hasTasks
                                      ? Center(
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: List.generate(
                      2,
                      (index) => Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: _filter == index
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: _filter == index
                                ? Colors.white
                                : AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => setState(() {
                            _filter = index;
                          }),
                          child: Text(
                            ['Theo ngày', 'Sắp tới'][index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Chưa hoàn tất'),
                    selected: _unfinishedOnly,
                    onSelected: (value) =>
                        setState(() => _unfinishedOnly = value),
                  ),
                ),
                Text(
                  _filter == 1
                      ? 'Công việc sắp tới'
                      : 'Lịch ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('Không có công việc trong mục này.'),
                  ),
                for (final task in tasks) _appointment(task),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointment(TechnicianTask task) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.scheduledAt.hour.toString().padLeft(2, '0')}:${task.scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_filter == 1)
                  Text(
                    '${task.scheduledAt.day}/${task.scheduledAt.month}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TaskBadge(
                      label: task.isMaintenance ? 'Bảo trì' : 'Sự cố',
                      color: task.isMaintenance
                          ? const Color(0xFFAC7300)
                          : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.location,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.status.label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          showTaskDetails(context, task, widget.onChanged),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        'Xem chi tiết ›',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
