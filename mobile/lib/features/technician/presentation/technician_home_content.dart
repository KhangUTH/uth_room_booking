import 'package:flutter/material.dart';

import '../../../shared/layouts/shell_catalog_content.dart';
import '../../booking/models/booking.dart';
import '../../notifications/models/app_notice.dart';
import '../controllers/maintenance_proposal_controller.dart';
import '../models/task_filter.dart';
import '../models/technician_task.dart';
import 'maintenance_proposals_page.dart';
import 'technician_assets_page.dart';
import 'technician_dashboard.dart';

class TechnicianHomeContent extends StatelessWidget {
  const TechnicianHomeContent({
    super.key,
    required this.jobs,
    required this.notices,
    required this.catalog,
    required this.refreshCatalog,
    required this.showAssets,
    required this.showMaintenance,
    required this.maintenance,
    required this.maintenanceAsset,
    required this.onWork,
    required this.onNotifications,
    required this.onAssets,
    required this.onMaintenance,
  });

  final List<TechnicianTask> jobs;
  final List<AppNotice>? notices;
  final ShellCatalogController catalog;
  final bool refreshCatalog;
  final bool showAssets;
  final bool showMaintenance;
  final MaintenanceProposalController maintenance;
  final BookingAsset? maintenanceAsset;
  final ValueChanged<TaskFilter?> onWork;
  final VoidCallback onNotifications;
  final VoidCallback onAssets;
  final void Function({BookingAsset? asset}) onMaintenance;

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: (showAssets ? 1 : 0) + (showMaintenance ? 1 : 0),
    children: [
      TechnicianDashboard(
        jobs: jobs,
        notices: notices,
        onWork: onWork,
        onNotifications: onNotifications,
        onAssets: onAssets,
        onMaintenance: onMaintenance,
      ),
      if (showAssets)
        catalog.content(
          (assets) => TechnicianAssetsPage(
            onAsset: (asset) => onMaintenance(asset: asset),
            catalog: assets,
            onRefresh: refreshCatalog ? catalog.reload : null,
          ),
        ),
      if (showMaintenance)
        catalog.content(
          (assets) => MaintenanceProposalsPage(
            controller: maintenance,
            initialAsset: maintenanceAsset,
            catalog: assets,
          ),
        ),
    ],
  );
}
