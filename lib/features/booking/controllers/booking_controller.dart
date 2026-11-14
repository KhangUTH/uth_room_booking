import '../../auth/models/user_role.dart';
import '../models/booking.dart';

/// Keeps the booking list and slot availability in sync for one app session.
class BookingController {
  static const minimumStudentCount = 10;

  BookingController({
    required this.today,
    required this.role,
    required Iterable<Booking> initialBookings,
  }) : _bookings = initialBookings.toList();

  final DateTime today;
  final UserRole role;
  final List<Booking> _bookings;

  Booking bookingAt(int index) => _bookings[index];

  List<int> indicesFor(DateTime? date) => [
    for (var index = _bookings.length - 1; index >= 0; index--)
      if (date == null || _bookings[index].slot.date == date) index,
  ];

  bool hasSchedule(DateTime day) =>
      day == today ||
      _bookings.any(
        (booking) => booking.slot.date == day && booking.status.holdsSlot,
      );

  SlotStatus statusFor(DateTime date, BookingAsset asset, int index) {
    final slot = (date: date, asset: asset.name, index: index);
    if (_bookings.any(
      (booking) => booking.slot == slot && booking.status.holdsSlot,
    )) {
      return SlotStatus.mine;
    }
    final status = asset.slots[index];
    return date == today || status == SlotStatus.maintenance
        ? status
        : SlotStatus.free;
  }

  bool register(
    BookingSlot slot,
    BookingAsset asset,
    CourseSection? section, {
    int? studentCount,
  }) {
    if (asset.capacity > 0) {
      if (role == UserRole.student &&
          (studentCount == null ||
              studentCount < minimumStudentCount ||
              studentCount > asset.capacity)) {
        return false;
      }
      if (role == UserRole.teacher && section == null) return false;
    }
    if (slot.date.isBefore(today) ||
        statusFor(slot.date, asset, slot.index) != SlotStatus.free) {
      return false;
    }
    _bookings.add((
      slot: slot,
      asset: asset,
      section: section,
      studentCount: studentCount,
      status: BookingStatus.pending,
    ));
    return true;
  }

  bool cancel(int index) {
    final booking = _bookings[index];
    if (booking.status != BookingStatus.pending) return false;
    _bookings[index] = (
      slot: booking.slot,
      asset: booking.asset,
      section: booking.section,
      studentCount: booking.studentCount,
      status: BookingStatus.cancelled,
    );
    return true;
  }
}
