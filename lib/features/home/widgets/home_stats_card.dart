import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';

import 'package:uth_room_booking/theme/app_colors.dart';

const _border = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class HomeStatsCard extends StatelessWidget {
  const HomeStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16004649),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _Stat('2', 'Lịch sắp tới')),
            VerticalDivider(width: 1, color: _border),
            Expanded(child: _Stat('1', 'Đang sử dụng')),
            VerticalDivider(width: 1, color: _border),
            Expanded(child: _Stat('12', 'Đã sử dụng')),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: AppTextSizes.metric,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: AppTextSizes.caption),
        ),
      ],
    ),
  );
}
