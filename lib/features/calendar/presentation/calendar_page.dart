import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/schedule_item.dart';
import '../data/sample_schedules.dart';

/// ===== TRANG LỊCH =====
class CalendarPage extends StatefulWidget {
  final DateTime? initialDate;
  const CalendarPage({super.key, this.initialDate});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _teal = AppColors.primary;
  static const _orange = Color(0xFFFF6A00);
  static const _eventBg = Color(0xFFB9E2E2);
  static const _eventBgSelected = Color(0xFF9BD1D1);

  static const _tabs = ['Đăng ký\nphòng', 'Lịch của tôi', 'Lịch sử\nđăng ký'];
  static const _weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  static const _weekdayNames = [
    'chủ nhật',
    'thứ hai',
    'thứ ba',
    'thứ tư',
    'thứ năm',
    'thứ sáu',
    'thứ bảy',
  ];

  int _tabIndex = 1;
  late int _month;
  late int _year;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  // ---------- helpers ----------
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ScheduleItem> _eventsOn(DateTime d) =>
      sampleSchedules.where((e) => _sameDay(e.date, d)).toList();

  void _changeMonth(int delta) {
    final d = DateTime(_year, _month + delta);
    if (d.year < 2020 || d.year > 2035) return;
    setState(() {
      _year = d.year;
      _month = d.month;
      _selected = null;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
        _selected = null;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selected == null
        ? <ScheduleItem>[]
        : _eventsOn(_selected!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTabs(),
          const SizedBox(height: 20),
          if (_tabIndex == 1)
            _buildCalendarCard()
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _tabIndex == 0
                    ? 'Chức năng đăng ký phòng đang được phát triển.'
                    : 'Chưa có dữ liệu lịch sử đăng ký.',
                textAlign: TextAlign.center,
              ),
            ),
          if (_tabIndex == 1 &&
              _selected != null &&
              selectedEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailPanel(_selected!, selectedEvents),
          ],
        ],
      ),
    );
  }

  // ---------- Tab ----------
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- Khung lịch ----------
  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildWeekdayRow(),
          const Divider(height: 16, color: Color(0xFFE2E8F0)),
          _buildGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Lịch theo tháng',
          style: TextStyle(
            color: _teal,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              key: const ValueKey('previous-month'),
              onTap: () => _changeMonth(-1),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.chevron_left, size: 22),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickMonth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD0D5DD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          'tháng $_month $_year',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              key: const ValueKey('next-month'),
              onTap: () => _changeMonth(1),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.chevron_right, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Center(
            child: Text(
              _weekdays[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: i == 0 ? _orange : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGrid() {
    final leading = DateTime(_year, _month, 1).weekday % 7; // CN = 0
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final rowCount = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rowCount, (r) {
        return Row(
          children: List.generate(7, (c) {
            final dayNum = r * 7 + c - leading + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 58));
            }
            return Expanded(
              child: _buildDayCell(DateTime(_year, _month, dayNum), c == 0),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSunday) {
    final events = _eventsOn(day);
    final hasEvents = events.isNotEmpty;
    final isToday = _sameDay(day, DateTime.now());
    final isSelected = _selected != null && _sameDay(day, _selected!);

    Color bg = Colors.white;
    if (hasEvents) bg = isSelected ? _eventBgSelected : _eventBg;

    // Màu chấm: xanh lá = LMS, cam = nguồn khác
    final dotColor = events.any((e) => e.source == 'LMS')
        ? const Color(0xFF7ED321)
        : _orange;

    return GestureDetector(
      onTap: () => setState(() => _selected = hasEvents ? day : null),
      child: Container(
        height: 54,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: _teal, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                color: isSunday ? _orange : const Color(0xFF333333),
              ),
            ),
            if (hasEvents) ...[
              const SizedBox(height: 3),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Panel chi tiết khi bấm vào ngày ----------
  Widget _buildDetailPanel(DateTime day, List<ScheduleItem> events) {
    final weekdayName = _weekdayNames[day.weekday % 7];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch $weekdayName, ngày ${_fmtDate(day)}',
                  style: const TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selected = null),
                child: const Icon(Icons.close, color: _teal),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFBFE3E0)),
          ...events.map(_buildEventCard),
        ],
      ),
    );
  }

  Widget _buildEventCard(ScheduleItem e) {
    const textColor = Color(0xFF1F3D2B);
    const label = TextStyle(fontWeight: FontWeight.bold, color: textColor);
    const value = TextStyle(color: textColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F9E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCDEFCD)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFF4F6EF7)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.code} - ${e.name}',
                      style: label.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Phòng: ', style: label),
                          TextSpan(text: e.room, style: value),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Thời gian: ', style: label),
                          TextSpan(text: e.time, style: value),
                        ],
                      ),
                    ),
                    if (e.source == 'LMS') ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 16,
                            color: Color(0xFFD32F2F),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LMS',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
