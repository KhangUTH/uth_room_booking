import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_sizes.dart';
import '../../booking/models/booking.dart';
import 'technician_panel.dart';

bool isAssetInMaintenance(BookingAsset asset) =>
    asset.slots.contains(SlotStatus.maintenance);

class TechnicianAssetCard extends StatelessWidget {
  const TechnicianAssetCard({
    super.key,
    required this.asset,
    required this.isRoom,
    required this.onTap,
  });

  final BookingAsset asset;
  final bool isRoom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = AssetStatusBadge(maintenance: isAssetInMaintenance(asset));
    final icon = CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.primary.withValues(alpha: .10),
      foregroundColor: AppColors.primary,
      child: Icon(
        isRoom ? Icons.apartment_outlined : Icons.devices_other_outlined,
        size: 17,
      ),
    );
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          asset.name,
          style: const TextStyle(
            fontSize: AppTextSizes.item,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          asset.detail,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: AppTextSizes.caption,
          ),
        ),
      ],
    );
    return TechnicianPanel(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isRoom
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [icon, description, badge],
                )
              : Row(
                  spacing: 10,
                  children: [
                    icon,
                    Expanded(child: description),
                    badge,
                  ],
                ),
        ),
      ),
    );
  }
}

class AssetStatusBadge extends StatelessWidget {
  const AssetStatusBadge({super.key, required this.maintenance, this.count});

  final bool maintenance;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = maintenance
        ? ('Bảo trì', const Color(0xFF815200), const Color(0xFFFFEFCF))
        : ('Hoạt động', const Color(0xFF126247), const Color(0xFFDDF4E8));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          count == null ? label : '$label · $count',
          style: TextStyle(
            color: color,
            fontSize: AppTextSizes.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
