class ScheduleItem {
  final DateTime date;
  final String code; // mã môn
  final String name; // tên môn / sự kiện
  final String room;
  final String time; // ví dụ: "Tiết 4 - 6 (09:25 - 11:55)"
  final String source; // "LMS" hoặc nguồn khác

  const ScheduleItem({
    required this.date,
    required this.code,
    required this.name,
    required this.room,
    required this.time,
    required this.source,
  });
}
