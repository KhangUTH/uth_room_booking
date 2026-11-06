import 'package:flutter/material.dart';
import 'package:uth_room_booking/features/profile/presentation/profile_page.dart';
import 'package:uth_room_booking/shared/layouts/footer.dart';

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
  late final List<TechnicianTask> _tasks = createSampleTechnicianTasks();

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _index,
        children: [
          TechnicianHomePage(
            name: widget.name,
            id: widget.id,
            tasks: _tasks,
            onChanged: _refresh,
          ),
          TechnicianSchedulePage(
            name: widget.name,
            id: widget.id,
            tasks: _tasks,
            onChanged: _refresh,
          ),
          TechnicianHomePage(
            name: widget.name,
            id: widget.id,
            tasks: _tasks,
            onChanged: _refresh,
            incidentsOnly: true,
          ),
          ProfilePage(name: widget.name, id: widget.id, isTechnician: true),
        ],
      ),
    ),
    bottomNavigationBar: MyFooter(
      currentIndex: _index,
      isTechnician: true,
      onTap: (value) => setState(() => _index = value),
    ),
  );
}
