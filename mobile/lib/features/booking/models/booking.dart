const bookingStartTimes = ['07:00', '09:30', '13:00', '15:30'];
const bookingEndTimes = ['09:00', '11:30', '15:00', '17:30'];

typedef CourseSection = ({String code, String name});

enum SlotStatus { free, booked, mine, maintenance }

enum ScheduleQuestion {
  today,
  tomorrow,
  next;

  static ScheduleQuestion? fromMessage(String message) {
    final words = message.toLowerCase().split(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
    );
    final text = ' ${words.where((word) => word.isNotEmpty).join(' ')} ';
    if (text.contains(' ngày mai ') || text.contains(' mai ')) {
      return tomorrow;
    }
    if (text.contains(' hôm nay ') || text.contains(' ngày hôm nay ')) {
      return today;
    }
    if (text.contains(' tiếp theo ') || text.contains(' sắp tới ')) {
      return next;
    }
    return null;
  }
}

enum BookingStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  bool get holdsSlot => this == pending || this == approved;
}

typedef BookingAsset = ({
  String? id,
  String name,
  String detail,
  int capacity,
  List<SlotStatus> slots,
});

typedef BookingSlot = ({DateTime date, String asset, int index});

extension BookingAssetIdentity on BookingAsset {
  String get bookingKey => id ?? name;
}

typedef Booking = ({
  BookingSlot slot,
  BookingAsset asset,
  CourseSection? section,
  int? studentCount,
  BookingStatus status,
});
