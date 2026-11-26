import 'package:supabase_flutter/supabase_flutter.dart';

import '../../booking/data/sample_booking_data.dart';
import '../data/maintenance_proposal_store.dart';
import '../models/maintenance_proposal.dart';

class MaintenanceProposalController {
  MaintenanceProposalController({SupabaseClient? client})
    : _store = client == null ? null : MaintenanceProposalStore(client),
      _proposals = client == null
          ? [
              MaintenanceProposal(
                asset: sampleBookingRooms[1],
                reason: 'Kiểm tra định kỳ máy trạm.',
                status: MaintenanceStatus.approved,
              ),
              MaintenanceProposal(
                asset: sampleBookingEquipment.first,
                reason: 'Kiểm tra nguồn cấp ổ điện.',
                status: MaintenanceStatus.rejected,
              ),
            ]
          : [];

  final MaintenanceProposalStore? _store;
  final List<MaintenanceProposal> _proposals;
  int _revision = 0;

  bool get isLive => _store != null;
  List<MaintenanceProposal> get proposals => List.unmodifiable(_proposals);

  Future<MaintenanceProposal?> proposalById(String id) async =>
      _store?.byId(id);

  Future<void> refresh() async {
    final store = _store;
    if (store == null) return;
    final revision = ++_revision;
    final rows = await store.list();
    if (revision != _revision) return;
    _proposals
      ..clear()
      ..addAll(rows);
  }

  Future<void> submit(MaintenanceProposal proposal) async {
    final store = _store;
    if (store == null) {
      _proposals.insert(0, proposal);
      return;
    }
    final saved = await store.submit(proposal);
    _revision++;
    _proposals.removeWhere((item) => item.id == saved.id);
    _proposals.insert(0, saved);
  }

  Future<void> cancel(MaintenanceProposal proposal) async {
    if (proposal.status != MaintenanceStatus.pending) return;
    final store = _store;
    final id = proposal.id;
    if (store != null && id != null) {
      final cancelled = await store.cancel(id);
      _revision++;
      final index = _proposals.indexWhere((item) => item.id == id);
      if (index != -1) _proposals[index] = cancelled;
      return;
    }
    final index = _proposals.indexOf(proposal);
    if (index == -1) return;
    _proposals[index] = MaintenanceProposal(
      asset: proposal.asset,
      reason: proposal.reason,
      status: MaintenanceStatus.cancelled,
    );
  }
}
