import 'package:flutter/material.dart';

import '../../booking/data/sample_booking_data.dart';

class MaintenanceScheduleField extends StatefulWidget {
  const MaintenanceScheduleField({
    super.key,
    required this.today,
    required this.date,
    required this.slotIndex,
    required this.onDateChanged,
    required this.onSlotChanged,
    required this.onClear,
  });

  final DateTime today;
  final DateTime? date;
  final int? slotIndex;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onSlotChanged;
  final VoidCallback onClear;

  @override
  State<MaintenanceScheduleField> createState() =>
      _MaintenanceScheduleFieldState();
}

class _MaintenanceScheduleFieldState extends State<MaintenanceScheduleField> {
  bool _calendarOpen = false;

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            FocusScope.of(context).unfocus();
            setState(() => _calendarOpen = !_calendarOpen);
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            date == null
                ? 'Thời gian dự kiến (tùy chọn)'
                : MaterialLocalizations.of(context).formatCompactDate(date),
          ),
        ),
        if (_calendarOpen)
          CalendarDatePicker(
            initialDate: date,
            firstDate: widget.today,
            lastDate: DateUtils.addDaysToDate(widget.today, 365),
            onDateChanged: (selected) {
              setState(() => _calendarOpen = false);
              widget.onDateChanged(selected);
            },
          ),
        if (date != null) ...[
          DropdownButtonFormField<int>(
            initialValue: widget.slotIndex,
            decoration: const InputDecoration(labelText: 'Ca dự kiến'),
            items: [
              for (var i = 0; i < bookingStartTimes.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    '${bookingStartTimes[i]} – ${bookingEndTimes[i]}',
                  ),
                ),
            ],
            onChanged: widget.onSlotChanged,
            validator: (index) =>
                index == null ? 'Chọn ca hoặc bỏ ngày dự kiến' : null,
          ),
          TextButton(
            onPressed: widget.onClear,
            child: const Text('Bỏ thời gian dự kiến'),
          ),
        ],
      ],
    );
  }
}
