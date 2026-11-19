import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _paleTeal = Color(0xFFDCEFEF);
const _border = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class HomeNoticeCard extends StatelessWidget {
  const HomeNoticeCard(
    this.icon,
    this.title,
    this.subtitle,
    this.age, {
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String age;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _paleTeal,
          foregroundColor: AppColors.primary,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTextSizes.item,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: AppTextSizes.caption,
                ),
              ),
            ],
          ),
        ),
        if (age.isNotEmpty) const SizedBox(width: 6),
        if (age.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _paleTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              age,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: AppTextSizes.badge,
              ),
            ),
          ),
      ],
    ),
  );
}
