const bookingStartTimes = ['07:00', '09:30', '13:00', '15:30'];
const bookingEndTimes = ['09:00', '11:30', '15:00', '17:30'];

typedef CourseSection = ({String code, String name});

enum SlotStatus { free, booked, mine, maintenance }

enum BookingStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  bool get holdsSlot => this == pending || this == approved;
}

typedef BookingAsset = ({
  String name,
  String detail,
  int capacity,
  List<SlotStatus> slots,
});

typedef BookingSlot = ({DateTime date, String asset, int index});

typedef Booking = ({
  BookingSlot slot,
  BookingAsset asset,
  CourseSection? section,
  int? studentCount,
  BookingStatus status,
});
