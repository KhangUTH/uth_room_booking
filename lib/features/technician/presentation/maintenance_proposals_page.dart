import 'package:flutter/material.dart';

import '../widgets/technician_page_title.dart';

import '../../booking/models/booking.dart';
import '../controllers/maintenance_proposal_controller.dart';
import '../widgets/maintenance_proposal_dialog.dart';
import '../widgets/maintenance_proposal_card.dart';
import '../../booking/widgets/booking_category_tabs.dart';

class MaintenanceProposalsPage extends StatefulWidget {
  const MaintenanceProposalsPage({
    super.key,
    required this.controller,
    this.initialAsset,
  });

  final MaintenanceProposalController controller;
  final BookingAsset? initialAsset;

  @override
  State<MaintenanceProposalsPage> createState() =>
      _MaintenanceProposalsPageState();
}

class _MaintenanceProposalsPageState extends State<MaintenanceProposalsPage> {
  late bool _rooms = (widget.initialAsset?.capacity ?? 1) > 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialAsset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _create(asset: widget.initialAsset);
      });
    }
  }

  Future<void> _create({BookingAsset? asset}) async {
    final proposal = await showMaintenanceProposalDialog(
      context,
      widget.controller,
      asset: asset,
      rooms: _rooms,
    );
    if (!mounted || proposal == null) return;
    setState(() => widget.controller.submit(proposal));
  }

  @override
  Widget build(BuildContext context) {
    final proposals = widget.controller.proposals
        .where((proposal) => (proposal.asset.capacity > 0) == _rooms)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TechnicianPageTitle('Đề xuất bảo trì'),
        const SizedBox(height: 10),
        BookingCategoryTabs(
          options: const [(true, 'Phòng máy'), (false, 'Thiết bị')],
          selected: _rooms,
          onChanged: (value) => setState(() => _rooms = value),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: const Text('Tạo đề xuất'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đề xuất đã gửi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (proposals.isEmpty) const Text('Chưa có đề xuất trong mục này.'),
        for (final proposal in proposals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MaintenanceProposalCard(
              proposal: proposal,
              onCancel: () =>
                  setState(() => widget.controller.cancel(proposal)),
            ),
          ),
      ],
    );
  }
}
