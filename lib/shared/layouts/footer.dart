import 'package:flutter/material.dart';

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
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: isTechnician
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: 'Lịch',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build_outlined),
                label: 'Sự cố',
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
                icon: Icon(Icons.help_outlined),
                label: 'Hỗ trợ',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
            ],
    );
  }
}
