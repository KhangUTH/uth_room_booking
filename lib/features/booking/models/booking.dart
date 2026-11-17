typedef CourseSection = ({String code, String name});

enum SlotStatus { free, booked, mine, maintenance }

enum BookingStatus {
  pending,
  approved,
  rejected,
  cancelled;

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
