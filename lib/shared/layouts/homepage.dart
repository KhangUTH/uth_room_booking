import "package:flutter/material.dart";
import "package:uth_room_booking/shared/layouts/footer.dart";
import "package:uth_room_booking/shared/layouts/header.dart";
import "package:uth_room_booking/features/room/models/room.dart";
import "package:uth_room_booking/features/room/data/sample_rooms.dart";
import "package:uth_room_booking/features/equipment/models/device.dart";
import "package:uth_room_booking/features/equipment/data/sample_devices.dart";
import "package:uth_room_booking/shared/widgets/preview_list_section.dart";
import "package:uth_room_booking/features/room/presentation/room_list_page.dart";
import "package:uth_room_booking/features/equipment/presentation/device_list_page.dart";
import "package:uth_room_booking/features/profile/presentation/profile_page.dart";
import "package:uth_room_booking/features/support/presentation/support_page.dart";
import 'package:uth_room_booking/features/calendar/presentation/calendar_page.dart';
import 'package:uth_room_booking/features/profile/models/user_profile.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String id;

  const HomePage({super.key, required this.name, required this.id});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  late UserProfile _profile = UserProfile(fullName: widget.name, id: widget.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _index == 3 || _index == 2
          ? null
          : MyHeader(name: _profile.fullName, id: _profile.id),
      body: IndexedStack(
        index: _index,
        children: [
          _buildBody(),
          const CalendarPage(),
          SupportPage(
            name: _profile.fullName,
            id: _profile.id,
            isActive: _index == 2,
          ),
          ProfilePage(
            name: _profile.fullName,
            id: _profile.id,
            profile: _profile,
            onProfileChanged: (value) => setState(() => _profile = value),
            onTabChange: (value) => setState(() => _index = value),
          ),
        ],
      ),
      bottomNavigationBar: MyFooter(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget _buildBody() {
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
