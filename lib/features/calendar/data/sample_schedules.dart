import '../models/schedule_item.dart';

final List<ScheduleItem> sampleSchedules = [
  ScheduleItem(
    date: DateTime(2026, 10, 11),
    code: '010412620111',
    name: 'Lập trình di động',
    room: 'B201 - CS1 (P.Thạnh Mỹ Tây, TP.HCM)',
    time: 'Tiết 1 - 3 (06:50 - 09:15)',
    source: 'Khác',
  ),
  ScheduleItem(
    date: DateTime(2026, 10, 23),
    code: '010412620229',
    name: 'Học kỳ doanh nghiệp',
    room: 'C303 - CS1 (P.Thạnh Mỹ Tây, TP.HCM)',
    time: 'Tiết 4 - 6 (09:25 - 11:55)',
    source: 'LMS',
  ),
];
