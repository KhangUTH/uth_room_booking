import 'package:supabase_flutter/supabase_flutter.dart';

import '../../booking/models/booking.dart';
import '../models/maintenance_proposal.dart';

class MaintenanceProposalStore {
  MaintenanceProposalStore(this._client);

  final SupabaseClient _client;
  static const _fields =
      'id,room_id,equipment_id,reason,status,'
      'rooms(name,location,capacity),equipment(name,location)';
  static const _timeout = Duration(seconds: 12);

  Future<MaintenanceProposal?> byId(String id) async {
    final row = await _client
        .from('maintenance_proposals')
        .select(_fields)
        .eq('id', id)
        .maybeSingle()
        .timeout(_timeout);
    return row == null ? null : _decode(row);
  }

  Future<List<MaintenanceProposal>> list() async {
    final rows = await _client
        .from('maintenance_proposals')
        .select(_fields)
        .order('created_at', ascending: false)
        .order('id')
        .timeout(_timeout);
    return rows.map(_decode).toList();
  }

  Future<MaintenanceProposal> submit(MaintenanceProposal proposal) async {
    final isRoom = proposal.asset.capacity > 0;
    final assetId = proposal.asset.id;
    if (assetId == null) {
      throw StateError('Danh mục chưa có mã tài sản.');
    }
    final row = await _client
        .from('maintenance_proposals')
        .insert({
          if (isRoom) 'room_id': assetId else 'equipment_id': assetId,
          'reason': proposal.reason,
        }, defaultToNull: false)
        .select(_fields)
        .single()
        .timeout(_timeout);
    return _decode(row);
  }

  Future<MaintenanceProposal> cancel(String id) async {
    final row = await _client
        .from('maintenance_proposals')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('status', 'pending')
        .select(_fields)
        .single()
        .timeout(_timeout);
    return _decode(row);
  }

  MaintenanceProposal _decode(Map<String, dynamic> row) {
    final room = row['rooms'] as Map<String, dynamic>?;
    final asset = room ?? row['equipment'] as Map<String, dynamic>;
    final name = asset['name'] as String;
    return MaintenanceProposal(
      id: row['id'] as String,
      asset: (
        id: (row['room_id'] ?? row['equipment_id']) as String?,
        name: name,
        detail: asset['location'] as String? ?? '',
        capacity: room?['capacity'] as int? ?? 0,
        slots: const <SlotStatus>[],
      ),
      reason: row['reason'] as String,
      status: MaintenanceStatus.values.byName(row['status'] as String),
    );
  }
}
