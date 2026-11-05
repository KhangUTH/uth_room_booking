import "package:flutter/material.dart";
import "package:uth_room_booking/navbar/footer.dart";
import "package:uth_room_booking/navbar/header.dart";
import "package:uth_room_booking/features/lists/models.dart";
import "package:uth_room_booking/features/lists/preview_list_section.dart";
import "package:uth_room_booking/features/lists/room_list_page.dart";
import "package:uth_room_booking/features/lists/device_list_page.dart";
import "package:uth_room_booking/features/profile/profile_page.dart";

class HomePage extends StatefulWidget {
  final String name;
  final String id;

  const HomePage({super.key, required this.name, required this.id});

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _index == 3
        ? null
        : MyHeader(
            name: widget.name,
            id: widget.id,
          ),
      body: _buildBody(),
      bottomNavigationBar: MyFooter(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget _buildBody() {
    if (_index == 3) {
      return ProfilePage(name: widget.name, id: widget.id);
    }
    // Tab 0 = Trang chủ. Các tab khác giữ placeholder như cũ.
    if (_index != 0) {
      return Center(child: Text('Đang ở tab $_index'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PreviewListSection<Room>(
            title: 'Danh sách phòng',
            items: sampleRooms,
            titleOf: (r) => r.name,
            subtitleOf: (r) => r.status,
            onSeeMore: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoomListPage()),
            ),
          ),
          const SizedBox(height: 16),
          PreviewListSection<Device>(
            title: 'Danh sách thiết bị',
            items: sampleDevices,
            titleOf: (d) => d.name,
            subtitleOf: (d) => d.status,
            onSeeMore: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceListPage()),
            ),
          ),
        ],
      ),
    );
  }
}