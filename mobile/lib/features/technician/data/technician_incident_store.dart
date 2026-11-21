import 'package:supabase_flutter/supabase_flutter.dart';

import '../../incident_report/data/incident_report_store.dart';
import '../models/technician_task.dart';

class TechnicianIncidentStore {
  TechnicianIncidentStore(this._client);

  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 15);

  Future<List<TechnicianTask>> jobs() async {
    final rows = await _client
        .rpc<List<dynamic>>('technician_incident_jobs')
        .timeout(_timeout);
    return rows.cast<Map<String, dynamic>>().map(_task).toList();
  }

  TechnicianTask _task(Map<String, dynamic> row) {
    final id = row['id'] as String;
    return TechnicianTask(
      title: row['title'] as String,
      location: row['asset_name'] as String,
      description: row['description'] as String? ?? '',
      reporter: row['reporter_name'] as String,
      scheduledAt: null,
      isUrgent: row['needs_support'] == true,
      status: _status(row),
      onAdvance: (status) async {
        try {
          final updated = await _client
              .rpc<Map<String, dynamic>>(
                'advance_technician_incident',
                params: {
                  'report_id': id,
                  'expected_status': status == TaskStatus.pending
                      ? 'open'
                      : 'in_progress',
                },
              )
              .timeout(_timeout);
          return _status(updated);
        } on PostgrestException catch (error) {
          if (error.message == 'Work already claimed by another technician' ||
              error.message == 'Work status changed; refresh first' ||
              error.message == 'Incident report not found') {
            throw const TechnicianTaskUnavailable();
          }
          rethrow;
        }
      },
      loadEvidence: row['has_photo'] == true
          ? () async => [?await IncidentReportStore.loadEvidence(_client, id)]
          : null,
    );
  }

  TaskStatus _status(Map<String, dynamic> row) => switch (row['status']) {
    'open' => TaskStatus.pending,
    'in_progress' => TaskStatus.inProgress,
    'resolved' => TaskStatus.completed,
    _ => throw const FormatException('Trạng thái công việc không hợp lệ.'),
  };
}
