import 'package:uth_room_booking/features/notifications/notifications.dart';
import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class MyHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String id;
  final double? height;
  final VoidCallback? onBellTap;
  final String? title;
  final IconData? titleIcon;
  final bool supportIdentity;
  final bool isTechnician;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? subtitle;

  static const double baseHeight = 140;
  static const double curveDepth = 20;

  const MyHeader({
    super.key,
    required this.name,
    required this.id,
    this.height,
    this.onBellTap,
    this.title,
    this.titleIcon,
    this.supportIdentity = false,
    this.isTechnician = false,
    this.showBackButton = false,
    this.onBack,
    this.subtitle,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    height ??
        baseHeight +
            (titleIcon == null ? 0 : 44) +
            (title == null ? 0 : 12 + title!.split('\n').length * 26) +
            (subtitle == null ? 0 : 22),
  );

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurveClipper(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: preferredSize.height + MediaQuery.paddingOf(context).top,
        ),
        width: double.infinity,
        color: AppColors.primary,

        child: SafeArea(
          bottom: false,
          child: Align(
            heightFactor: 1,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (showBackButton)
                        BackButton(color: Colors.white, onPressed: onBack),
                      // Avatar
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(
                          Icons.person_outline,
                          size: 36,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Thông tin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isTechnician
                                  ? 'Tên KTV'
                                  : supportIdentity
                                  ? 'Tên SV/GV'
                                  : 'Tên'}: $name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isTechnician
                                  ? 'Mã KTV'
                                  : supportIdentity
                                  ? 'MSSV/MSGV'
                                  : 'Mssv'}: $id',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nút chuông
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE0E0E0),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Thông báo',
                          icon: const Icon(
                            Icons.notifications_none,
                            size: 20,
                            color: Colors.black,
                          ),
                          onPressed:
                              onBellTap ?? () => openNotifications(context),
                        ),
                      ),
                    ],
                  ),
                  if (titleIcon != null) ...[
                    const SizedBox(height: 8),
                    Icon(titleIcon, color: Colors.white, size: 36),
                  ],
                  if (title != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cắt đáy header thành hình vòng cung
class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const curve = MyHeader.curveDepth;

    final path = Path()
      ..lineTo(0, size.height - curve)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curve, // điểm điều khiển
        size.width,
        size.height - curve, // điểm cuối
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
