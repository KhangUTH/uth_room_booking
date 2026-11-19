import 'package:flutter/foundation.dart';

import '../../auth/models/user_role.dart';
import '../data/booking_store.dart';
import '../data/sample_booking_data.dart';
import '../models/booking.dart';

/// Keeps the booking list and slot availability in sync for one app session.
class BookingController extends ChangeNotifier {
  static const minimumStudentCount = 10;

  BookingController({
    required this.today,
    required this.role,
    required Iterable<Booking> initialBookings,
    this.store,
  }) : _bookings = [
         for (final booking in initialBookings) (id: null, booking: booking),
       ];

  final DateTime today;
  final UserRole role;
  final BookingStore? store;
  final List<({String? id, Booking booking})> _bookings;
  int _historyRequest = 0;
  bool _historyLoaded = false;
  bool get hasHistory => _historyLoaded;
  Set<BookingSlot> busy = {};

  ({int upcoming, int inUse, int used})? homeCounts() {
    if (store != null && !_historyLoaded) return null;
    final now = store == null ? DateTime.now() : BookingStore.campusNow;
    final clock = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    var upcoming = 0;
    var inUse = 0;
    var used = 0;
    for (final entry in _bookings) {
      final booking = entry.booking;
      if (booking.status == BookingStatus.completed) {
        used++;
        continue;
      }
      if (!booking.status.holdsSlot) continue;
      final slot = booking.slot;
      if (slot.index < 0 || slot.index >= bookingStartTimes.length) continue;
      DateTime timeAt(String time) {
        final parts = time.split(':');
        return DateTime.utc(
          slot.date.year,
          slot.date.month,
          slot.date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      final start = timeAt(bookingStartTimes[slot.index]);
      if (start.isAfter(clock)) {
        upcoming++;
      } else if (booking.status == BookingStatus.approved &&
          timeAt(bookingEndTimes[slot.index]).isAfter(clock)) {
        inUse++;
      }
    }
    return (upcoming: upcoming, inUse: inUse, used: used);
  }

  Future<void> refreshHistory() async {
    final source = store;
    if (source == null) return;
    final request = ++_historyRequest;
    final rows = await source.history();
    if (request != _historyRequest) return;
    _bookings
      ..clear()
      ..addAll(rows);
    _historyLoaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _historyRequest++;
    super.dispose();
  }

  String? savedBookingId(int index) => _bookings[index].id;

  Booking bookingAt(int index) => _bookings[index].booking;

  List<int> indicesFor(DateTime? date, {bool cancelledLast = false}) {
    final indices = <int>[];
    final cancelled = <int>[];
    for (var index = _bookings.length - 1; index >= 0; index--) {
      final booking = bookingAt(index);
      if (date != null && booking.slot.date != date) continue;
      final target = cancelledLast && booking.status == BookingStatus.cancelled
          ? cancelled
          : indices;
      target.add(index);
    }
    return indices..addAll(cancelled);
  }

  bool hasSchedule(DateTime day) =>
      day == today ||
      _bookings.any(
        (entry) =>
            entry.booking.slot.date == day && entry.booking.status.holdsSlot,
      );

  SlotStatus statusFor(DateTime date, BookingAsset asset, int index) {
    final slot = (date: date, asset: asset.name, index: index);
    if (_bookings.any(
      (entry) => entry.booking.slot == slot && entry.booking.status.holdsSlot,
    )) {
      return SlotStatus.mine;
    }
    final status = asset.slots[index];
    if (store != null &&
        status != SlotStatus.maintenance &&
        busy.contains(slot)) {
      return SlotStatus.booked;
    }
    return date == today || status == SlotStatus.maintenance
        ? status
        : SlotStatus.free;
  }

  bool hasStudentRoomBooking(DateTime date, int index) =>
      role == UserRole.student &&
      _bookings.any((entry) {
        final booking = entry.booking;
        return booking.asset.capacity > 0 &&
            booking.status.holdsSlot &&
            booking.slot.date == date &&
            booking.slot.index == index;
      });

  bool register(
    BookingSlot slot,
    BookingAsset asset,
    CourseSection? section, {
    int? studentCount,
  }) {
    if (asset.capacity > 0) {
      if (hasStudentRoomBooking(slot.date, slot.index)) return false;
      if (role == UserRole.student &&
          (studentCount == null ||
              studentCount < minimumStudentCount ||
              studentCount > asset.capacity)) {
        return false;
      }
      if (role == UserRole.teacher &&
          (section == null || asset.name == sampleLibraryRoomName)) {
        return false;
      }
    }
    if (slot.date.isBefore(today) ||
        statusFor(slot.date, asset, slot.index) != SlotStatus.free) {
      return false;
    }
    final booking = (
      slot: slot,
      asset: asset,
      section: section,
      studentCount: studentCount,
      status: BookingStatus.pending,
    );
    _bookings.add((id: null, booking: booking));
    notifyListeners();
    return true;
  }

  bool cancel(int index) {
    final (id: id, booking: booking) = _bookings[index];
    if (booking.status != BookingStatus.pending) return false;
    final cancelled = (
      slot: booking.slot,
      asset: booking.asset,
      section: booking.section,
      studentCount: booking.studentCount,
      status: BookingStatus.cancelled,
    );
    _bookings[index] = (id: id, booking: cancelled);
    notifyListeners();
    return true;
  }
}
