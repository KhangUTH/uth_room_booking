import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

class TechnicianHeader extends StatelessWidget {
  final String name;
  final String id;
  final String? title;

  const TechnicianHeader({
    super.key,
    required this.name,
    required this.id,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(MediaQuery.sizeOf(context).width / 2, 38),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFDDEBE9),
                child: Icon(
                  Icons.person_outline,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tên KTV: $name\nMã KTV: $id',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Thông báo',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bạn chưa có thông báo mới.')),
                  );
                },
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 18),
            Text(
              title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Phòng/thiết bị được phân công',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
