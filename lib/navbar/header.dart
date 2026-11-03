import 'package:flutter/material.dart';

class MyHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String id;
  final double height;
  final VoidCallback? onBellTap;

  const MyHeader({
    super.key,
    required this.name,
    required this.id,
    this.height = 200,
    this.onBellTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurveClipper(),
      child: Container(
        height: height + 45,
        width: double.infinity,
        color: Colors.teal,
        
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 35, 16, 10),
              child: Row(
                children: [
                  // Avatar
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person_outline, size: 36, color: Colors.black),
                  ),
                  const SizedBox(width: 12),

                  // Thông tin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tên: $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mssv: $id',
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
                      icon: const Icon(Icons.notifications_none,
                          size: 20, color: Colors.black),
                      onPressed: onBellTap,
                    ),
                  ),
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
    const curve = 45.0; // độ cong, tăng số này để cong nhiều hơn

    final path = Path()
      ..lineTo(0, size.height - curve)
      ..quadraticBezierTo(
        size.width / 2, size.height + curve, // điểm điều khiển
        size.width, size.height - curve,     // điểm cuối
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}