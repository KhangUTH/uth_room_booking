import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.items,
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
      selectedItemColor: AppColors.primary,
      unselectedItemColor: const Color(0xFF53797B),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      showUnselectedLabels: true,
      items: items,
    );
  }
}
