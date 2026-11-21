import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'booking_panel.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

extension _BookingStatusStyle on BookingStatus {
  (String, IconData, Color, Color) get _style => switch (this) {
    BookingStatus.pending => (
      'Chờ duyệt',
      Icons.hourglass_top,
      const Color(0xFF885400),
      const Color(0xFFFFF0CC),
    ),
    BookingStatus.approved => (
      'Đã duyệt',
      Icons.check,
      const Color(0xFF006747),
      const Color(0xFFD9F8E9),
    ),
    BookingStatus.rejected => (
      'Từ chối',
      Icons.close,
      const Color(0xFFA62936),
      const Color(0xFFFDE6E8),
    ),
    BookingStatus.cancelled => (
      'Đã hủy',
      Icons.event_busy_outlined,
      _muted,
      const Color(0xFFEBEFEF),
    ),
    BookingStatus.completed => (
      'Đã hoàn thành',
      Icons.done_all,
      const Color(0xFF006747),
      const Color(0xFFD9F8E9),
    ),
  };

  String get label => _style.$1;
  IconData get icon => _style.$2;
  Color get color => _style.$3;
  Color get background => _style.$4;
}

class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({super.key, required this.booking, this.onCancel});

  final Booking booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final slot = booking.slot;
    final status = booking.status;
    final section = booking.section;
    final isRoom = booking.asset.capacity > 0;
    return BookingPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: status.background,
                foregroundColor: status.color,
                child: Icon(
                  isRoom ? Icons.desktop_windows_outlined : Icons.devices_other,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.asset.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      booking.asset.detail,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, color: status.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: _line),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _bookingMeta(
                Icons.calendar_today_outlined,
                MaterialLocalizations.of(context).formatCompactDate(slot.date),
              ),
              _bookingMeta(
                Icons.schedule,
                '${bookingStartTimes[slot.index]} – ${bookingEndTimes[slot.index]}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: status.background.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    'Chi tiết ca ${bookingStartTimes[slot.index]}',
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (section != null) ...[
                    _bookingDetail('Mã học phần', section.code),
                    _bookingDetail('Lớp học phần', section.name),
                  ] else
                    _bookingDetail(
                      'Loại đăng ký',
                      isRoom ? 'Phòng máy' : 'Thiết bị',
                    ),
                  if (booking.studentCount case final count?)
                    _bookingDetail('Số sinh viên', '$count'),
                ],
              ),
            ),
          ),
          if (onCancel != null && status == BookingStatus.pending)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.event_busy_outlined, size: 16),
                label: const Text('Hủy lịch'),
                style: TextButton.styleFrom(
                  foregroundColor: BookingStatus.rejected.color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingMeta(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.primary),
      const SizedBox(width: 5),
      Text(value, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _bookingDetail(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
