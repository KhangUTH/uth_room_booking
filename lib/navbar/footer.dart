import 'package:flutter/material.dart';

class MyFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MyFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch'),
        BottomNavigationBarItem(icon: Icon(Icons.help_outlined), label: 'Hỗ trợ'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
      ],
    );
  }
}