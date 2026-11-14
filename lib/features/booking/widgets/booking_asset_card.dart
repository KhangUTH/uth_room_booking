import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/booking.dart';
import 'booking_status_badge.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const _muted = Color(0xFF526E74);

class BookingAssetCard extends StatelessWidget {
  const BookingAssetCard({
    super.key,
    required this.asset,
    required this.status,
    required this.past,
    required this.onTap,
  });

  final BookingAsset asset;
  final SlotStatus status;
  final bool past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = status == SlotStatus.free && !past;
    final (label, foreground, background) = switch (status) {
      SlotStatus.free when past => ('Đã qua', _muted, Colors.white),
      SlotStatus.free => ('Trống', AppColors.primary, Colors.white),
      SlotStatus.booked => ('Đã đặt', _muted, const Color(0xFFEBEDEF)),
      SlotStatus.mine => (
        'Của bạn',
        AppColors.primary,
        const Color(0xFFEAF6F5),
      ),
      SlotStatus.maintenance => (
        'Đang bảo trì',
        const Color(0xFF785100),
        const Color(0xFFFFF5DF),
      ),
    };
    final accentBackground = switch (status) {
      SlotStatus.booked => const Color(0xFFDFE3E6),
      SlotStatus.maintenance => const Color(0xFFF1D99F),
      _ => _pale,
    };
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: available || status == SlotStatus.mine
              ? const Color(0xFFACD6D6)
              : _line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: available ? onTap : null,
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: accentBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              status == SlotStatus.maintenance
                  ? Icons.build_outlined
                  : asset.capacity > 0
                  ? Icons.desktop_windows_outlined
                  : Icons.devices_other_outlined,
              color: foreground,
              size: 18,
            ),
          ),
        ),
        title: Text(
          asset.name,
          style: TextStyle(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          asset.detail,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        trailing: available
            ? const Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: AppColors.primary,
                semanticLabel: 'Trống',
              )
            : BookingStatusBadge(
                label,
                color: foreground,
                background: switch (status) {
                  SlotStatus.booked ||
                  SlotStatus.mine ||
                  SlotStatus.maintenance => accentBackground,
                  _ => const Color(0xFFF1F5F5),
                },
              ),
      ),
    );
  }
}
