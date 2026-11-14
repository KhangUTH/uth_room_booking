import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class MyHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String id;
  final String idLabel;

  final VoidCallback? onBellTap;
  final bool continueIntoBody;
  final bool hasUnreadNotifications;

  const MyHeader({
    super.key,
    required this.name,
    required this.id,
    required this.idLabel,
    this.onBellTap,
    this.continueIntoBody = false,
    this.hasUnreadNotifications = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(128);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: continueIntoBody
          ? BorderRadius.zero
          : const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: ColoredBox(
        color: AppColors.appBar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: -38,
              right: -48,
              child: CircleAvatar(
                radius: 96,
                backgroundColor: AppColors.appBarAccent,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.appBar,
                      child: Icon(Icons.person_outline, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xin chào,',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              child: Text(
                                '$idLabel: $id',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Thông báo',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white24,
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed: onBellTap,
                      icon: Badge(
                        isLabelVisible: hasUnreadNotifications,
                        backgroundColor: const Color(0xFFFFCF64),
                        child: const Icon(Icons.notifications_none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
