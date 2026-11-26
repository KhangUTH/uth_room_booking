import 'package:flutter/material.dart';

import '../../../core/router/app_route.dart';
import '../../incident_report/data/incident_report_store.dart';
import '../../technician/controllers/maintenance_proposal_controller.dart';
import '../../technician/data/technician_incident_store.dart';
import '../../technician/widgets/maintenance_proposal_card.dart';
import '../models/app_notice.dart';
import '../widgets/notice_details_sheet.dart';

Future<void> openProposalNotice(
  BuildContext context,
  AppNotice notice,
  MaintenanceProposalController controller,
  String proposalId,
) => _openLinked(
  context,
  () => controller.proposalById(proposalId),
  (proposal) => showMaintenanceProposalDetails(context, proposal),
  () => showNoticeDetails(context, notice, null),
);

Future<void> openTechnicianNotice(
  BuildContext context,
  AppNotice notice,
  TechnicianIncidentStore store,
  String reportId,
) => _openLinked(
  context,
  () => store.jobById(reportId),
  (task) => Navigator.of(context).pushNamed<void>(
    AppRoute.technicianTask,
    arguments: (task: task, onChanged: () {}),
  ),
  () => showNoticeDetails(context, notice, null),
);

Future<void> openReporterNotice(
  BuildContext context,
  IncidentReportStore store,
  String reportId,
) => _openLinked(
  context,
  () => store.reportById(reportId),
  (report) => showNoticeIncidentDetails(context, store, report),
  () => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'Chưa mở được báo cáo. Bạn có thể xem trong Báo cáo của tôi.',
        ),
      ),
    ),
);

Future<void> _openLinked<T>(
  BuildContext context,
  Future<T?> Function() load,
  void Function(T) open,
  VoidCallback unavailable,
) async {
  T? record;
  try {
    record = await load();
  } catch (_) {
    // The inbox remains available when the linked record cannot be loaded.
  }
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
  if (record == null) {
    unavailable();
  } else {
    open(record);
  }
}
