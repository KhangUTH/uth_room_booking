import 'package:flutter/material.dart';

import 'models.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách phòng')),
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
