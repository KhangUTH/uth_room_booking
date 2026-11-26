import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

class BookingStore {
  BookingStore(this._client);

  final SupabaseClient _client;

  static DateTime get campusNow =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  DateTime _campusTime(String value) =>
      DateTime.parse(value).toUtc().add(const Duration(hours: 7));

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  int _index(DateTime time) => bookingStartTimes.indexOf(
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
  );

  String _timestamp(DateTime day, String clock) =>
      '${day.toIso8601String().split('T').first}T$clock:00+07:00';

  bool hasStarted(DateTime day, int index) =>
      !DateTime.parse(_timestamp(day, bookingStartTimes[index]))
          .isAfter(DateTime.now());

  static const _bookingFields =
      'id,room_id,equipment_id,start_time,status,student_count,rooms(name,location,capacity),'
      'equipment(name,location),teaching_sections(code,name)';

  Future<Booking?> bookingById(String id) async {
    final row = await _client
        .from('bookings')
        .select(_bookingFields)
        .eq('id', id)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));
    return row == null ? null : _decode(row).booking;
  }

  Future<List<({String id, Booking booking})>> history() async {
    final rows = await _client
        .from('bookings')
        .select(_bookingFields)
        .order('created_at')
        .order('id')
        .timeout(const Duration(seconds: 10));
    return [for (final row in rows) _decode(row)];
  }

  ({String id, Booking booking}) _decode(Map<String, dynamic> row) {
    final room = row['rooms'] as Map<String, dynamic>?;
    final asset = room ?? row['equipment'] as Map<String, dynamic>;
    final course = row['teaching_sections'] as Map<String, dynamic>?;
    final time = _campusTime(row['start_time'] as String);
    final name = asset['name'] as String;
    final assetId = (row['room_id'] ?? row['equipment_id']) as String;
    return (
      id: row['id'] as String,
      booking: (
        slot: (date: _day(time), asset: assetId, index: _index(time)),
        asset: (
          id: assetId,
          name: name,
          detail: asset['location'] as String? ?? '',
          capacity: room?['capacity'] as int? ?? 0,
          slots: const [],
        ),
        section: course == null
            ? null
            : (code: course['code'] as String, name: course['name'] as String),
        studentCount: row['student_count'] as int?,
        status: BookingStatus.values.byName(row['status'] as String),
      ),
    );
  }

  Future<Set<BookingSlot>> busySlots(DateTime day) async {
    final rows = await _client
        .rpc<List<dynamic>>(
          'mobile_busy_booking_slots',
          params: {'day': day.toIso8601String().split('T').first},
        )
        .timeout(const Duration(seconds: 10));
    final slots = <BookingSlot>{};
    for (final row in rows) {
      final assetId = (row['room_id'] ?? row['equipment_id']) as String?;
      final index = _index(_campusTime(row['start_time'] as String));
      if (assetId != null && index >= 0) {
        slots.add((date: day, asset: assetId, index: index));
      }
    }
    return slots;
  }

  Future<List<CourseSection>> courses() async {
    final rows = await _client
        .from('teaching_sections')
        .select('code,name')
        .order('code')
        .timeout(const Duration(seconds: 10));
    return [
      for (final row in rows)
        (code: row['code'] as String, name: row['name'] as String),
    ];
  }

  Future<void> create(
    BookingSlot slot,
    BookingAsset asset, {
    CourseSection? section,
    int? studentCount,
  }) async {
    final assetId = asset.id;
    if (assetId == null || slot.asset != assetId) {
      throw StateError('Đăng ký thiếu ID tài sản hợp lệ.');
    }
    final sectionId = section == null
        ? null
        : (await _client
              .from('teaching_sections')
              .select('id')
              .eq('code', section.code)
              .single())['id'];
    await _client.from('bookings').insert({
      if (asset.capacity > 0) 'room_id': assetId else 'equipment_id': assetId,
      'start_time': _timestamp(slot.date, bookingStartTimes[slot.index]),
      'end_time': _timestamp(slot.date, bookingEndTimes[slot.index]),
      'student_count': studentCount,
      'teaching_section_id': sectionId,
    });
  }

  Future<void> cancel(String id) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('status', 'pending')
        .select('id')
        .single();
  }
}
