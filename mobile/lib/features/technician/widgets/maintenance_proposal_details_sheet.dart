import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/maintenance_proposal.dart';
import 'task_details.dart';

class MaintenanceProposalDetailsSheet extends StatelessWidget {
  const MaintenanceProposalDetailsSheet({
    super.key,
    required this.proposal,
    required this.statusColor,
  });

  final MaintenanceProposal proposal;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final isRoom = proposal.asset.capacity > 0;
    return FractionallySizedBox(
      heightFactor: .92,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo/logo.jpg',
                height: 40,
                fit: BoxFit.contain,
                semanticLabel: 'Logo UTH',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chi tiết đề xuất',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _DetailBox(
              icon: isRoom
                  ? Icons.apartment_outlined
                  : Icons.devices_other_outlined,
              label: isRoom ? 'Phòng máy' : 'Thiết bị',
              child: Text(
                proposal.asset.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _DetailBox(
              icon: Icons.place_outlined,
              label: 'Thông tin tài sản',
              child: Text(proposal.asset.detail),
            ),
            _DetailBox(
              icon: Icons.check_circle_outline,
              label: 'Trạng thái',
              child: TaskBadge(
                label: proposal.status.label,
                color: statusColor,
              ),
            ),
            _DetailBox(
              icon: Icons.description_outlined,
              label: 'Lý do bảo trì',
              child: Text(proposal.reason),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        child,
      ],
    ),
  );
}
