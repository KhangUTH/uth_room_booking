import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';
import '../../booking/data/sample_booking_data.dart';
import '../../booking/widgets/booking_calendar.dart';
import '../../booking/widgets/booking_category_tabs.dart';
import '../../booking/widgets/booking_history_card.dart';

class TechnicianSchedulePage extends StatefulWidget {
  const TechnicianSchedulePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TechnicianSchedulePage> createState() => _TechnicianSchedulePageState();
}

enum _AssetCategory { room, equipment }

class _TechnicianSchedulePageState extends State<TechnicianSchedulePage> {
  final _today = DateUtils.dateOnly(DateTime.now());
  late final _bookings = createSampleUsageSchedule(_today);
  late DateTime _selectedDate = _today;
  _AssetCategory _category = _AssetCategory.room;

  @override
  Widget build(BuildContext context) {
    final bookings = _bookings.where(
      (booking) =>
          booking.slot.date == _selectedDate &&
          (booking.asset.capacity > 0) == (_category == _AssetCategory.room),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      children: [
        SizedBox(
          height: 48,
          child: NavigationToolbar(
            leading: IconButton(
              tooltip: 'Quay lại Công việc kỹ thuật',
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            middle: const Text(
              'Lịch sử dụng',
              style: TextStyle(
                fontSize: AppTextSizes.section,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        BookingCalendar(
          date: _selectedDate,
          hasSchedule: (day) =>
              _bookings.any((booking) => booking.slot.date == day),
          onDateChanged: (day) => setState(() => _selectedDate = day),
        ),
        const SizedBox(height: 12),
        BookingCategoryTabs(
          options: const [
            (_AssetCategory.room, 'Phòng máy'),
            (_AssetCategory.equipment, 'Thiết bị'),
          ],
          selected: _category,
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Không có lịch đã duyệt trong ngày này')),
          ),
        for (final booking in bookings)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BookingHistoryCard(booking: booking),
          ),
      ],
    );
  }
}
