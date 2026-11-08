import 'package:uth_room_booking/shared/layouts/header.dart';
import 'package:flutter/material.dart';

import '../data/sample_devices.dart';

class DeviceListPage extends StatelessWidget {
  final String name;
  final String id;

  const DeviceListPage({super.key, this.name = '', this.id = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyHeader(
        name: name,
        id: id,
        title: 'Danh sách thiết bị',
        showBackButton: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleDevices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final d = sampleDevices[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.devices_other),
              title: Text(d.name),
              subtitle: Text(d.status),
            ),
          );
        },
      ),
    );
  }
}
