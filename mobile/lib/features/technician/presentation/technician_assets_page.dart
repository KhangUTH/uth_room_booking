import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';
import '../../booking/data/asset_catalog.dart';
import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../widgets/technician_asset_card.dart';
import '../widgets/technician_page_title.dart';

class TechnicianAssetsPage extends StatelessWidget {
  const TechnicianAssetsPage({
    super.key,
    required this.onAsset,
    this.catalog,
    this.onRefresh,
  });

  final ValueChanged<BookingAsset> onAsset;
  final AssetCatalog? catalog;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final rooms = catalog?.rooms ?? sampleBookingRooms;
    final devices = catalog?.equipment ?? sampleBookingEquipment;
    final assets = [...rooms, ...devices];
    final maintenanceCount = assets.where(isAssetInMaintenance).length;
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const TechnicianPageTitle('Phòng và thiết bị phụ trách'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            AssetStatusBadge(
              maintenance: false,
              count: assets.length - maintenanceCount,
            ),
            AssetStatusBadge(maintenance: true, count: maintenanceCount),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('Phòng máy', rooms.length),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final width = constraints.maxWidth;
            final cardWidth = width < 250 ? width : (width - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final room in rooms)
                  SizedBox(
                    width: cardWidth,
                    child: TechnicianAssetCard(
                      asset: room,
                      isRoom: true,
                      onTap: () => onAsset(room),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _SectionTitle('Thiết bị', devices.length),
        const SizedBox(height: 8),
        for (final equipment in devices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TechnicianAssetCard(
              asset: equipment,
              isRoom: false,
              onTap: () => onAsset(equipment),
            ),
          ),
      ],
    );
    final refresh = onRefresh;
    return refresh == null
        ? content
        : RefreshIndicator(onRefresh: refresh, child: content);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, this.count);

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Text(
    '$label · $count',
    style: const TextStyle(
      fontSize: AppTextSizes.item,
      fontWeight: FontWeight.w700,
    ),
  );
}
