import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/technician_task.dart';

class TechnicianWorkStore {
  TechnicianWorkStore(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;
  static const _timeout = Duration(seconds: 15);

  void _checkSession() {
    if (_client.auth.currentUser?.id != _userId) {
      throw const AuthException('Phiên đăng nhập đã thay đổi.');
    }
  }

  Future<List<TechnicianTask>> load() async {
    _checkSession();
    final rows = await _client
        .rpc<List<dynamic>>('technician_incident_jobs')
        .timeout(_timeout);
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        if (row['approved_at'] != null &&
            (row['assigned_to'] == _userId ||
                (row['assigned_to'] == null && row['status'] == 'open')))
          _decode(row),
    ];
  }

  TechnicianTask _decode(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final course = row['course_section'] as String?;
    return TechnicianTask(
      id: id,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      location: row['asset_name'] as String? ?? 'Tài sản',
      reporter: [
        row['reporter_name'] as String? ?? 'Người báo cáo',
        if (course != null && course.isNotEmpty) course,
      ].join(' · '),
      scheduledAt: null,
      isUrgent: row['needs_support'] == true,
      status: _status(row['status']),
      statusUpdatedAt: DateTime.tryParse(
        row['status_updated_at'] as String? ?? '',
      )?.toLocal(),
      saveProgress: (expected) => _advance(id, expected),
      returnToQueue: () async {
        _checkSession();
        await _client
            .rpc('release_technician_incident', params: {'report_id': id})
            .timeout(_timeout);
      },
      loadEvidence: row['has_photo'] == true ? () => _evidence(id) : null,
    );
  }

  TaskStatus _status(Object? value) => switch (value) {
    'open' => TaskStatus.pending,
    'in_progress' => TaskStatus.inProgress,
    'resolved' => TaskStatus.completed,
    _ => throw const FormatException('Trạng thái công việc không hợp lệ.'),
  };

  Future<SavedTaskProgress> _advance(String id, TaskStatus expected) async {
    _checkSession();
    final row = await _client
        .rpc<Map<String, dynamic>>(
          'advance_technician_incident',
          params: {
            'report_id': id,
            'expected_status': expected == TaskStatus.pending
                ? 'open'
                : 'in_progress',
          },
        )
        .timeout(_timeout);
    return (
      status: _status(row['status']),
      updatedAt: DateTime.parse(row['status_updated_at'] as String).toLocal(),
    );
  }

  Future<List<Uint8List>> _evidence(String id) async {
    _checkSession();
    final path = await _client
        .rpc<String?>('incident_evidence_path', params: {'report_id': id})
        .timeout(_timeout);
    if (path == null) return [];
    return [
      await _client.storage
          .from('incident-images')
          .download(path)
          .timeout(_timeout),
    ];
  }
}
