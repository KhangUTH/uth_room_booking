import 'package:flutter/material.dart';

import 'booking_panel.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);
const _tomorrowDot = Color(0xFFE68726);

class BookingCalendar extends StatelessWidget {
  const BookingCalendar({
    super.key,
    required this.date,
    required this.today,
    required this.hasSchedule,
    required this.onDateChanged,
  });

  final DateTime date;
  final DateTime today;
  final bool Function(DateTime) hasSchedule;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) => BookingPanel(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Tuần trước',
              onPressed: () => onDateChanged(DateUtils.addDaysToDate(date, -7)),
              icon: const Icon(Icons.chevron_left, color: _muted),
            ),
            Expanded(
              child: Text(
                'Tháng ${date.month}, ${date.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Tuần sau',
              onPressed: () => onDateChanged(DateUtils.addDaysToDate(date, 7)),
              icon: const Icon(Icons.chevron_right, color: _muted),
            ),
          ],
        ),
        Row(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 3),
                  child: _buildDay(
                    DateUtils.addDaysToDate(
                      DateUtils.addDaysToDate(date, 1 - date.weekday),
                      index,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _buildDay(DateTime day) {
    final selected = day == date;
    final tomorrow = DateUtils.addDaysToDate(today, 1);
    final dotColor = switch (day) {
      _ when DateUtils.isSameDay(day, today) => AppColors.primary,
      _ when DateUtils.isSameDay(day, tomorrow) && hasSchedule(day) =>
        _tomorrowDot,
      _ when hasSchedule(day) => AppColors.primary,
      _ => Colors.transparent,
    };
    final sundayTextColor = day.weekday == DateTime.sunday
        ? const Color(0xFFC35151)
        : null;
    return Material(
      color: selected ? _pale : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? AppColors.primary : _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onDateChanged(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            children: [
              Text(
                day.weekday == DateTime.sunday ? 'CN' : 'T${day.weekday + 1}',
                style: TextStyle(fontSize: 11, color: sundayTextColor),
              ),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: sundayTextColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 3),
              CircleAvatar(radius: 3, backgroundColor: dotColor),
            ],
          ),
        ),
      ),
    );
  }
}
