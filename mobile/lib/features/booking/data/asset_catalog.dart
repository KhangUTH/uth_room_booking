import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

typedef AssetCatalog = ({
  List<BookingAsset> rooms,
  List<BookingAsset> equipment,
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
  final validRooms = rows[0].where((room) => room['capacity'] is int);
  final orderedRooms = [
    ...validRooms.where((room) => room['is_active'] == true),
    ...validRooms.where((room) => room['is_active'] != true),
  ];

  return (
    roomsUnavailableToTeachers: {
      for (final room in rows[0])
        if (room['allows_teacher_booking'] == false) room['id'] as String,
    },
    rooms: [
      for (final room in orderedRooms)
        (
          id: room['id'] as String,
          name: room['name'] as String,
          detail: '${room['location']} · ${room['capacity']} máy',
          capacity: room['capacity'] as int,
          slots: previewSlots(room['is_active'] == true),
        ),
    ],
    equipment: [
      for (final device in rows[1])
        (
          id: device['id'] as String,
          name: device['name'] as String,
          detail: (device['location'] as String?) ?? 'Thiết bị chung',
          capacity: 0,
          slots: previewSlots(device['status'] == 'available'),
        ),
    ],
  );
}
