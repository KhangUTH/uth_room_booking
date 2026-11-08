import 'package:uth_room_booking/shared/layouts/header.dart';
import 'package:flutter/material.dart';

import '../data/sample_rooms.dart';

class RoomListPage extends StatelessWidget {
  final String name;
  final String id;

  const RoomListPage({super.key, this.name = '', this.id = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyHeader(
        name: name,
        id: id,
        title: 'Danh sách phòng',
        showBackButton: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleRooms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = sampleRooms[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.meeting_room),
              title: Text(r.name),
              subtitle: Text(r.status),
            ),
          );
        },
      ),
    );
  }
}
