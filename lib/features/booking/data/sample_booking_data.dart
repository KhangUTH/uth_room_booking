import '../../auth/models/user_role.dart';
import '../models/booking.dart';

const bookingStartTimes = ['07:00', '09:30', '13:00', '15:30'];
const bookingEndTimes = ['09:00', '11:30', '15:00', '17:30'];

const List<CourseSection> sampleTeachingCourses = [
  (code: 'CNTT301', name: 'Lập trình di động', group: 'Nhóm 02'),
  (code: 'CNTT301', name: 'Lập trình di động', group: 'Nhóm 03'),
  (code: 'CNTT302', name: 'Cơ sở dữ liệu', group: 'Nhóm 01'),
  (code: 'CNTT303', name: 'Phát triển ứng dụng web', group: 'Nhóm 01'),
];

const List<BookingAsset> sampleBookingRooms = [
  (
    name: 'Phòng B2-304',
    detail: '40 máy · Tầng 3 · Tòa B2',
    capacity: 40,
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
    slots: [
      SlotStatus.booked,
      SlotStatus.booked,
      SlotStatus.free,
      SlotStatus.free,
    ],
  ),
  (
    name: 'Phòng thư viện',
    detail: 'Tòa K · Tầng 1 · 20 máy',
    capacity: 20,
    slots: [SlotStatus.free, SlotStatus.free, SlotStatus.free, SlotStatus.free],
  ),
];

const List<BookingAsset> sampleBookingEquipment = [
  (
    name: 'Máy chiếu Epson',
    detail: 'Thiết bị trình chiếu · Tòa B2',
    capacity: 0,
    slots: [
      SlotStatus.free,
      SlotStatus.booked,
      SlotStatus.free,
      SlotStatus.maintenance,
    ],
  ),
  (
    name: 'Laptop Dell',
    detail: 'Thiết bị học tập · Tòa B1',
    capacity: 0,
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
        section: role == UserRole.teacher ? sampleTeachingCourses[2] : null,
        studentCount: role == UserRole.student ? 10 : null,
        status: BookingStatus.rejected,
      ),
    ],
  ];
}

/// Approved bookings represented by the demo's shared availability and timetable.
List<Booking> createSampleUsageSchedule(DateTime today) => [
  for (final asset in [...sampleBookingRooms, ...sampleBookingEquipment])
    for (var index = 0; index < asset.slots.length; index++)
      if (asset.slots[index] == SlotStatus.booked)
        (
          slot: (date: today, asset: asset.name, index: index),
          asset: asset,
          section: null,
          studentCount: null,
          status: BookingStatus.approved,
        ),
  ...createSampleBookings(
    today,
    UserRole.teacher,
  ).where((booking) => booking.status == BookingStatus.approved),
]..sort((a, b) => a.slot.index.compareTo(b.slot.index));
