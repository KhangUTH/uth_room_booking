import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';
import '../../booking/data/booking_store.dart';
import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../../booking/widgets/booking_calendar.dart';
import '../../booking/widgets/booking_category_tabs.dart';
import '../../booking/widgets/booking_history_card.dart';

class TechnicianSchedulePage extends StatefulWidget {
  const TechnicianSchedulePage({
    super.key,
    required this.onBack,
    this.store,
    this.active = true,
  });

  final VoidCallback onBack;
  final BookingStore? store;
  final bool active;

  @override
  State<TechnicianSchedulePage> createState() => _TechnicianSchedulePageState();
}

enum _AssetCategory { room, equipment }

class _TechnicianSchedulePageState extends State<TechnicianSchedulePage> {
  late final _today = DateUtils.dateOnly(
    widget.store == null ? DateTime.now() : BookingStore.campusNow,
  );
  late final _sampleBookings = createSampleUsageSchedule(_today);
  late DateTime _selectedDate = _today;
  _AssetCategory _category = _AssetCategory.room;
  Future<List<Booking>>? _schedule;

  DateTime _weekStart(DateTime day) =>
      DateUtils.addDaysToDate(day, 1 - day.weekday);

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _schedule = widget.store?.technicianSchedule(_weekStart(_selectedDate));
    }
  }

  @override
  void didUpdateWidget(covariant TechnicianSchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _schedule = widget.store?.technicianSchedule(_weekStart(_selectedDate));
    }
  }

  void _selectDate(DateTime day) {
    setState(() {
      if (_weekStart(_selectedDate) != _weekStart(day)) {
        _schedule = widget.store?.technicianSchedule(_weekStart(day));
      }
      _selectedDate = day;
    });
  }

  Future<void> _refresh() async {
    final request = widget.store?.technicianSchedule(_weekStart(_selectedDate));
    if (request == null) return;
    setState(() {
      _schedule = request;
    });
    try {
      await request;
    } catch (_) {
      // FutureBuilder shows the retry state.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Booking>>(
    future: _schedule,
    builder: (context, snapshot) {
      final content = _buildCalendar(snapshot);
      return widget.store == null
          ? content
          : RefreshIndicator(onRefresh: _refresh, child: content);
    },
  );

  Widget _buildCalendar(AsyncSnapshot<List<Booking>> snapshot) {
    final visibleSchedule = widget.store == null
        ? _sampleBookings
        : snapshot.connectionState == ConnectionState.waiting
        ? const <Booking>[]
        : (snapshot.data ?? const <Booking>[]);
    final bookings = visibleSchedule.where(
      (booking) =>
          booking.slot.date == _selectedDate &&
          (booking.asset.capacity > 0) == (_category == _AssetCategory.room),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
          today: _today,
          hasSchedule: (day) =>
              visibleSchedule.any((booking) => booking.slot.date == day),
          onDateChanged: _selectDate,
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
        if (snapshot.connectionState == ConnectionState.waiting)
          const LinearProgressIndicator()
        else if (snapshot.hasError)
          TextButton(
            onPressed: _refresh,
            child: const Text('Không tải được lịch sử dụng. Thử lại'),
          )
        else if (bookings.isEmpty)
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
