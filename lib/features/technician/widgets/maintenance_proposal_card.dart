import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../booking/data/sample_booking_data.dart';
import '../../booking/models/booking.dart';
import '../models/maintenance_proposal.dart';
import 'maintenance_proposal_details_sheet.dart';
import 'task_details.dart';
import 'technician_panel.dart';

class MaintenanceProposalCard extends StatelessWidget {
  const MaintenanceProposalCard({
    super.key,
    required this.proposal,
    required this.onCancel,
  });

  final MaintenanceProposal proposal;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final schedule = proposal.schedule;
    final color = switch (proposal.status) {
      MaintenanceStatus.pending => const Color(0xFF815200),
      MaintenanceStatus.approved => const Color(0xFF126247),
      MaintenanceStatus.rejected => const Color(0xFFAE251A),
      MaintenanceStatus.cancelled => AppColors.textMuted,
    };
    return TechnicianPanel(
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (context) => MaintenanceProposalDetailsSheet(
            proposal: proposal,
            statusColor: color,
            scheduleLabel: _scheduleLabel(context, schedule),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Icon(
                    proposal.asset.capacity > 0
                        ? Icons.apartment_outlined
                        : Icons.devices_other_outlined,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      proposal.asset.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TaskBadge(label: proposal.status.label, color: color),
                ],
              ),
              Text(proposal.asset.detail),
              Text(
                proposal.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(_scheduleLabel(context, schedule)),
              if (proposal.status == MaintenanceStatus.pending)
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Hủy đề xuất'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(BuildContext context, BookingSlot? schedule) =>
      schedule == null
      ? 'Chưa chọn thời gian'
      : '${MaterialLocalizations.of(context).formatCompactDate(schedule.date)} · '
            '${bookingStartTimes[schedule.index]} – ${bookingEndTimes[schedule.index]}';
}
