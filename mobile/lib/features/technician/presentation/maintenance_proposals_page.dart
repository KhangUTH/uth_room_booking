import 'dart:async';

import 'package:flutter/material.dart';

import '../../booking/data/asset_catalog.dart';
import '../../booking/models/booking.dart';
import '../../booking/widgets/booking_category_tabs.dart';
import '../controllers/maintenance_proposal_controller.dart';
import '../models/maintenance_proposal.dart';
import '../widgets/maintenance_proposal_card.dart';
import '../widgets/maintenance_proposal_dialog.dart';
import '../widgets/technician_page_title.dart';

class MaintenanceProposalsPage extends StatefulWidget {
  const MaintenanceProposalsPage({
    super.key,
    required this.controller,
    this.initialAsset,
    this.catalog,
  });

  final MaintenanceProposalController controller;
  final BookingAsset? initialAsset;
  final AssetCatalog? catalog;

  @override
  State<MaintenanceProposalsPage> createState() =>
      _MaintenanceProposalsPageState();
}

class _MaintenanceProposalsPageState extends State<MaintenanceProposalsPage> {
  late bool _rooms = (widget.initialAsset?.capacity ?? 1) > 0;
  Timer? _refreshTimer;
  bool _loading = false;
  bool _changing = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.isLive) {
      _refresh();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          _refresh();
        }
      });
    }
    if (widget.initialAsset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _create(asset: widget.initialAsset);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading || _changing) return;
    _loading = true;
    try {
      await widget.controller.refresh();
      if (mounted) setState(() => _loadFailed = false);
    } catch (_) {
      if (mounted && !_loadFailed) setState(() => _loadFailed = true);
    } finally {
      _loading = false;
    }
  }

  Future<void> _cancel(MaintenanceProposal proposal) async {
    if (_changing) return;
    _changing = true;
    try {
      await widget.controller.cancel(proposal);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không hủy được đề xuất. Kiểm tra trạng thái rồi thử lại.',
            ),
          ),
        );
      }
    } finally {
      _changing = false;
    }
  }

  Future<void> _create({BookingAsset? asset}) async {
    final proposal = await showMaintenanceProposalDialog(
      context,
      widget.controller,
      asset: asset,
      rooms: _rooms,
      assets: _rooms ? widget.catalog?.rooms : widget.catalog?.equipment,
    );
    if (!mounted || proposal == null) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final proposals = widget.controller.proposals
        .where((proposal) => (proposal.asset.capacity > 0) == _rooms)
        .toList();
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
        if (_loadFailed)
          TextButton(
            onPressed: _refresh,
            child: const Text('Không tải được đề xuất. Thử lại'),
          ),
        if (proposals.isEmpty && !_loadFailed)
          const Text('Chưa có đề xuất trong mục này.'),
        for (final proposal in proposals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MaintenanceProposalCard(
              proposal: proposal,
              onCancel: () => _cancel(proposal),
            ),
          ),
      ],
    );
    return widget.controller.isLive
        ? RefreshIndicator(onRefresh: _refresh, child: list)
        : list;
  }
}
