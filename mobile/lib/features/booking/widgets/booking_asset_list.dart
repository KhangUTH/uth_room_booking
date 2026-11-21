import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'booking_asset_card.dart';
import 'booking_hint.dart';
import 'booking_slot_picker.dart';

const _muted = Color(0xFF526E74);
const _headingColor = Color(0xFF303638);

class BookingAssetList extends StatelessWidget {
  const BookingAssetList({
    super.key,
    required this.assets,
    required this.isRoom,
    required this.slotIndex,
    required this.past,
    required this.roomSlotTaken,
    required this.availableCount,
    required this.statusFor,
    required this.onSlotSelected,
    required this.onAssetSelected,
  });

  final List<BookingAsset> assets;
  final bool isRoom;
  final int slotIndex;
  final bool past;
  final bool roomSlotTaken;
  final int Function(int) availableCount;
  final SlotStatus Function(BookingAsset) statusFor;
  final ValueChanged<int> onSlotSelected;
  final ValueChanged<BookingAsset> onAssetSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 14),
      BookingSlotPicker(
        selectedIndex: slotIndex,
        availableCount: availableCount,
        onSelected: onSlotSelected,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Text(
              isRoom ? 'Danh sách phòng' : 'Danh sách thiết bị',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _headingColor,
              ),
            ),
          ),
          Text(
            '${availableCount(slotIndex)} trống · Ca ${slotIndex + 1}',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final asset in assets)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BookingAssetCard(
            asset: asset,
            status: statusFor(asset),
            past: past,
            roomSlotTaken: roomSlotTaken,
            onTap: () => onAssetSelected(asset),
          ),
        ),
      if (roomSlotTaken)
        const BookingHint(label: 'Bạn đã đăng ký một phòng trong ca này')
      else if (availableCount(slotIndex) > 0)
        BookingHint(
          label: isRoom
              ? 'Chạm một phòng trống để đặt'
              : 'Chạm một thiết bị trống để đăng ký sử dụng',
        ),
    ],
  );
}
