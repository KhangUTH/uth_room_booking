import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';

class MaintenanceAssetField extends StatelessWidget {
  const MaintenanceAssetField({
    super.key,
    required this.rooms,
    required this.initialValue,
    required this.onChanged,
  });

  final bool rooms;
  final BookingAsset? initialValue;
  final ValueChanged<BookingAsset?> onChanged;

  @override
  Widget build(BuildContext context) {
    final assets = rooms ? sampleBookingRooms : sampleBookingEquipment;
    final categoryIcon = rooms
        ? Icons.apartment_outlined
        : Icons.devices_other_outlined;

    return FormField<BookingAsset>(
      initialValue: initialValue,
      validator: (asset) => asset == null ? 'Chọn tài sản cần bảo trì' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            rooms ? 'Chọn phòng máy' : 'Chọn thiết bị',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          for (var start = 0; start < assets.length; start += 2)
            IntrinsicHeight(
              child: Row(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final asset in assets.skip(start).take(2))
                    Expanded(
                      child: _AssetOption(
                        name: asset.name,
                        icon: switch (asset.name) {
                          'Ổ điện' => Icons.power_outlined,
                          'Bàn phím A4Tech KR-83' => Icons.keyboard_outlined,
                          'Tai nghe Logitech H340' => Icons.headphones_outlined,
                          'Chuột Logitech M331 Silent Plus' =>
                            Icons.mouse_outlined,
                          'Micro TOA DM-1100' => Icons.mic_none,
                          _ => categoryIcon,
                        },
                        selected: field.value == asset,
                        onTap: () {
                          field.didChange(asset);
                          onChanged(asset);
                        },
                      ),
                    ),
                  if (start + 1 == assets.length)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          if (field.errorText case final error?)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class _AssetOption extends StatelessWidget {
  const _AssetOption({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 78),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        foregroundColor: selected ? AppColors.primary : AppColors.textDark,
        backgroundColor: selected ? const Color(0xFFDCEFEF) : AppColors.field,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          Text(name, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
