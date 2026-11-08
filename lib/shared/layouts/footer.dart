import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class MyFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isTechnician;

  const MyFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isTechnician = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: isTechnician
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                label: 'Công việc',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: 'Lịch',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Cá nhân',
              ),
            ]
          : const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Lịch',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.report_problem_outlined),
                label: 'Báo cáo',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
            ],
    );
  }
}
