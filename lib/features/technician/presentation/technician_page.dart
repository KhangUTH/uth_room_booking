import 'package:uth_room_booking/features/notifications/notifications.dart';
import 'package:flutter/material.dart';
import 'package:uth_room_booking/features/profile/presentation/profile_page.dart';
import 'package:uth_room_booking/shared/layouts/footer.dart';
import 'package:uth_room_booking/features/profile/models/user_profile.dart';

import '../models/technician_task.dart';
import 'technician_home_page.dart';
import 'technician_schedule_page.dart';

class TechnicianPage extends StatefulWidget {
  final String name;
  final String id;
  const TechnicianPage({super.key, required this.name, required this.id});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
  int _index = 0;
  final _notifications = NotificationController();

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  late UserProfile _profile = UserProfile(fullName: widget.name, id: widget.id);
  late final List<TechnicianTask> _tasks = createSampleTechnicianTasks();

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => NotificationScope(
    controller: _notifications,
    child: Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _index,
          children: [
            TechnicianHomePage(
              name: _profile.fullName,
              id: _profile.id,
              tasks: _tasks,
              onChanged: _refresh,
            ),
            TechnicianSchedulePage(
              name: _profile.fullName,
              id: _profile.id,
              tasks: _tasks,
              onChanged: _refresh,
            ),
            ProfilePage(
              name: _profile.fullName,
              id: _profile.id,
              isTechnician: true,
              profile: _profile,
              onProfileChanged: (value) => setState(() => _profile = value),
              onTabChange: (value) => setState(() => _index = value),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyFooter(
        currentIndex: _index,
        isTechnician: true,
        onTap: (value) => setState(() => _index = value),
      ),
    ),
  );
}
