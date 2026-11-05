import 'package:flutter/material.dart';

import 'models.dart';

class DeviceListPage extends StatelessWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách thiết bị')),
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
