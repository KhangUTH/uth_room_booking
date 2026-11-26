import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../models/booking.dart';
import 'booking_confirmation_sheet.dart';

Future<BookingSelection?> confirmBooking(
  BuildContext context, {
  required BookingSlot slot,
  required BookingAsset asset,
  required UserRole role,
  required List<CourseSection> courses,
}) => showModalBottomSheet<BookingSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 720),
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black26,
  builder: (_) => BookingConfirmationSheet(
    slot: slot,
    asset: asset,
    role: role,
    courses: courses,
  ),
);

Future<bool?> confirmBookingCancellation(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch đăng ký?'),
        content: const Text('Ca này sẽ được trả lại danh sách ca trống.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lịch'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFAD3037),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
