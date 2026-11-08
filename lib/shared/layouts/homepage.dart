import 'package:uth_room_booking/features/notifications/notifications.dart';
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
import 'package:uth_room_booking/features/support/presentation/report_issue_page.dart';
import 'package:uth_room_booking/features/support/models/support_request.dart';
import 'package:uth_room_booking/features/support/widgets/support_widgets.dart';
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
  final _requests = <SupportRequest>[];
  final _notifications = NotificationController();

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  late UserProfile _profile = UserProfile(fullName: widget.name, id: widget.id);

  @override
  Widget build(BuildContext context) {
    return NotificationScope(
      controller: _notifications,
      child: Scaffold(
        appBar: _index == 3 || _index == 2
            ? null
            : MyHeader(name: _profile.fullName, id: _profile.id),
        body: IndexedStack(
          index: _index,
          children: [
            _buildBody(),
            const CalendarPage(),
            SupportLayout(
              name: _profile.fullName,
              id: _profile.id,
              title: 'BÁO CÁO SỰ CỐ',
              icon: Icons.report_problem_outlined,
              isCenter: true,
              child: ReportIssuePage(
                onSave: (request) => setState(() => _requests.add(request)),
              ),
            ),
            ProfilePage(
              name: _profile.fullName,
              id: _profile.id,
              profile: _profile,
              supportRequests: _requests,
              isActive: _index == 3,
              onProfileChanged: (value) => setState(() => _profile = value),
              onTabChange: (value) => setState(() => _index = value),
            ),
          ],
        ),
        bottomNavigationBar: MyFooter(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
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
              MaterialPageRoute(
                builder: (_) => NotificationScope(
                  controller: _notifications,
                  child: RoomListPage(name: _profile.fullName, id: _profile.id),
                ),
              ),
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
              MaterialPageRoute(
                builder: (_) => NotificationScope(
                  controller: _notifications,
                  child: DeviceListPage(
                    name: _profile.fullName,
                    id: _profile.id,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
