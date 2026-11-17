import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

typedef AssetCatalog = ({
  List<BookingAsset> rooms,
  List<BookingAsset> equipment,
  Map<String, String> namesById,
  Set<String> roomsUnavailableToTeachers,
});

Future<AssetCatalog> loadAssetCatalog(SupabaseClient client) async {
  final rows = await Future.wait([
    client
        .from('rooms')
        .select('id,name,location,capacity,is_active,allows_teacher_booking')
        .eq('is_archived', false)
        .order('name'),
    client
        .from('equipment')
        .select('id,name,status,location')
        .isFilter('room_id', null)
        .order('name'),
  ]).timeout(const Duration(seconds: 10));

  List<SlotStatus> previewSlots(bool active) => List.filled(
    bookingStartTimes.length,
    active ? SlotStatus.free : SlotStatus.maintenance,
    growable: false,
  );

  return (
    roomsUnavailableToTeachers: {
      for (final room in rows[0])
        if (room['allows_teacher_booking'] == false) room['name'] as String,
    },
    namesById: {
      for (final row in rows.expand((group) => group))
        row['id'] as String: row['name'] as String,
    },
    rooms: [
      for (final room in rows[0])
        (
          name: room['name'] as String,
          detail: '${room['location']} · ${room['capacity']} máy',
          capacity: room['capacity'] as int,
          slots: previewSlots(room['is_active'] == true),
        ),
    ],
    equipment: [
      for (final device in rows[1])
        (
          name: device['name'] as String,
          detail: (device['location'] as String?) ?? 'Thiết bị chung',
          capacity: 0,
          slots: previewSlots(device['status'] == 'available'),
        ),
    ],
  );
}
