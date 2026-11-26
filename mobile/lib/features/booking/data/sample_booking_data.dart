import '../../auth/models/user_role.dart';
import '../models/booking.dart';

const sampleLibraryRoomName = 'Phòng thư viện';

const List<CourseSection> sampleTeachingCourses = [
  (code: 'CN2302E', name: 'Lập trình Web'),
  (code: 'CN2301B', name: 'Lập trình thiết bị di động'),
  (code: 'CN2302C', name: 'Lập trình mạng'),
];

const _freeSlots = [
  SlotStatus.free,
  SlotStatus.free,
  SlotStatus.free,
  SlotStatus.free,
];

const List<BookingAsset> sampleBookingRooms = [
  (
    name: 'Phòng B2-304',
    detail: '40 máy · Tầng 3 · Tòa B2',
    capacity: 40,
    id: null,
    slots: [
      SlotStatus.booked,
      SlotStatus.free,
      SlotStatus.free,
      SlotStatus.free,
    ],
  ),
  (
    name: 'Phòng B2-305',
    detail: '30 máy · Tầng 3 · Tòa B2',
    capacity: 30,
    id: null,
    slots: [
      SlotStatus.free,
      SlotStatus.free,
      SlotStatus.booked,
      SlotStatus.maintenance,
    ],
  ),
  (
    name: 'Phòng B1-201',
    detail: '50 máy · Tầng 2 · Tòa B1',
    capacity: 50,
    id: null,
    slots: [
      SlotStatus.booked,
      SlotStatus.booked,
      SlotStatus.free,
      SlotStatus.free,
    ],
  ),
  (
    name: sampleLibraryRoomName,
    detail: 'Tòa K · Tầng 1 · 20 máy',
    capacity: 20,
    id: null,
    slots: _freeSlots,
  ),
];

const List<BookingAsset> sampleBookingEquipment = [
  (
    name: 'Ổ điện',
    detail: 'Thiết bị chung',
    capacity: 0,
    id: null,
    slots: [
      SlotStatus.free,
      SlotStatus.booked,
      SlotStatus.free,
      SlotStatus.maintenance,
    ],
  ),
  (
    name: 'Bàn phím A4Tech KR-83',
    detail: 'Thiết bị chung',
    capacity: 0,
    id: null,
    slots: _freeSlots,
  ),
  (
    name: 'Tai nghe Logitech H340',
    detail: 'Thiết bị chung',
    capacity: 0,
    id: null,
    slots: _freeSlots,
  ),
  (
    name: 'Chuột Logitech M331 Silent Plus',
    detail: 'Thiết bị chung',
    capacity: 0,
    id: null,
    slots: _freeSlots,
  ),
  (
    name: 'Micro TOA DM-1100',
    detail: 'Thiết bị chung',
    capacity: 0,
    id: null,
    slots: [
      SlotStatus.free,
      SlotStatus.free,
      SlotStatus.booked,
      SlotStatus.free,
    ],
  ),
];

List<Booking> createSampleBookings(DateTime today, UserRole role) {
  return [
    if (role != UserRole.technician) ...[
      (
        slot: (
          date: DateTime(today.year, today.month, today.day + 1),
          asset: sampleBookingRooms[0].name,
          index: 2,
        ),
        asset: sampleBookingRooms[0],
        section: role == UserRole.teacher ? sampleTeachingCourses[0] : null,
        studentCount: role == UserRole.student ? 15 : null,
        status: BookingStatus.approved,
      ),
      (
        slot: (
          date: DateTime(today.year, today.month, today.day + 2),
          asset: sampleBookingRooms[1].name,
          index: 0,
        ),
        asset: sampleBookingRooms[1],
        section: role == UserRole.teacher ? sampleTeachingCourses[1] : null,
        studentCount: role == UserRole.student ? 10 : null,
        status: BookingStatus.rejected,
      ),
    ],
  ];
}

/// Approved bookings represented by the demo's shared availability and timetable.
