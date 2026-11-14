import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../data/sample_booking_data.dart';
import 'booking_status_badge.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);
const _headingColor = Color(0xFF303638);

class BookingSlotPicker extends StatelessWidget {
  const BookingSlotPicker({
    super.key,
    required this.selectedIndex,
    required this.availableCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int Function(int) availableCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Row(
        children: [
          Expanded(
            child: Text(
              'Chọn ca',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _headingColor,
              ),
            ),
          ),
          Text(
            'Mỗi lượt đặt một ca',
            style: TextStyle(fontSize: 11, color: _muted),
          ),
        ],
      ),
      const SizedBox(height: 8),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 5,
          children: [
            for (var index = 0; index < bookingStartTimes.length; index++)
              Expanded(child: _buildSlot(index, availableCount(index))),
          ],
        ),
      ),
    ],
  );

  Widget _buildSlot(int index, int available) {
    final selected = selectedIndex == index;
    final color = selected ? Colors.white : AppColors.primary;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.primary : _line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ca ${index + 1}',
                  style: TextStyle(
                    color: selected ? Colors.white : _headingColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${bookingStartTimes[index]}–${bookingEndTimes[index]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 10),
                ),
                const SizedBox(height: 5),
                BookingStatusBadge(
                  '$available trống',
                  color: color,
                  background: selected ? Colors.white24 : _pale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
