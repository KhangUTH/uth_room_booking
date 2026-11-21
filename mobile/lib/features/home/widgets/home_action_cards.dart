import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _paleTeal = Color(0xFFDCEFEF);
const _border = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class HomeActionRow extends StatelessWidget {
  const HomeActionRow({super.key, required this.first, required this.second});
  final HomeActionCard first;
  final HomeActionCard second;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    ),
  );
}

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.featured = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: featured ? AppColors.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: featured ? AppColors.primary : _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: featured ? Colors.white24 : _paleTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: featured ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTextSizes.action,
                  fontWeight: FontWeight.w700,
                  color: featured ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppTextSizes.caption,
                  color: featured ? Colors.white : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
