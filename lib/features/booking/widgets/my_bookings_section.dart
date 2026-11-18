import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'booking_history_card.dart';

List<Widget> buildMyBookingItems({
  required List<int> indices,
  required Booking Function(int) bookingAt,
  required bool showAllDates,
  required ValueChanged<bool> onShowAllDatesChanged,
  ValueChanged<int>? onCancel,
}) => [
  Align(
    alignment: Alignment.centerLeft,
    child: FilterChip(
      label: const Text('Tất cả ngày'),
      selected: showAllDates,
      onSelected: onShowAllDatesChanged,
    ),
  ),
  if (indices.isEmpty)
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          showAllDates
              ? 'Bạn chưa có đăng ký nào'
              : 'Bạn chưa có đăng ký trong ngày này',
        ),
      ),
    ),
  for (final index in indices)
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BookingHistoryCard(
        booking: bookingAt(index),
        onCancel: onCancel == null ? null : () => onCancel(index),
      ),
    ),
];
