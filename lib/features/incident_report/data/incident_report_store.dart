import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident_report.dart';

typedef StoredIncidentReport = ({
  String id,
  IncidentReport report,
  IncidentStatus status,
  DateTime? updatedAt,
  bool hasPhoto,
});

typedef IncidentAssets = ({
  Map<String, String> rooms,
  Map<String, String> equipment,
});

class IncidentReportStore {
  IncidentReportStore(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;
  static const _timeout = Duration(seconds: 15);
  static const _fields =
      'id,report_number,title,description,status,occurred_at,created_at,'
      'course_section,needs_support,has_photo,status_updated_at,'
      'room_id,equipment_id,approved_at,rooms(name),equipment(name)';

  void _checkSession() {
    if (_client.auth.currentUser?.id != _userId) {
      throw const AuthException('Phiên đăng nhập đã thay đổi.');
    }
  }

  Future<IncidentAssets> assets() async {
    _checkSession();
    final rows = await Future.wait([
      _client
          .from('rooms')
          .select('id,name')
          .eq('is_archived', false)
          .order('name'),
      _client
          .from('equipment')
          .select('id,name')
          .isFilter('room_id', null)
          .order('name'),
    ]).timeout(_timeout);
    return (
      rooms: {
        for (final row in rows[0]) row['id'] as String: row['name'] as String,
      },
      equipment: {
        for (final row in rows[1]) row['id'] as String: row['name'] as String,
      },
    );
  }

  Future<List<String>> teachingSections() async {
    _checkSession();
    final rows = await _client
        .from('teaching_sections')
        .select('code,name')
        .eq('lecturer_id', _userId)
        .order('code')
        .timeout(_timeout);
    return [for (final row in rows) '${row['code']} · ${row['name']}'];
  }

  String newSubmissionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  StorageFileApi get _images => _client.storage.from('incident-images');
  String _imagePath(String id) => '$_userId/${id.replaceAll('-', '')}.png';

  Future<List<StoredIncidentReport>> history() async {
    _checkSession();
    final rows = await _client
        .from('incident_reports')
        .select(_fields)
        .eq('reporter_id', _userId)
        .order('created_at', ascending: false)
        .order('report_number', ascending: false)
        .timeout(_timeout);
    return rows.map(_decode).toList();
  }

  Future<StoredIncidentReport> submit(
    String submissionId,
    IncidentReport report,
  ) async {
    _checkSession();
    final existing = await _client
        .from('incident_reports')
        .select(_fields)
        .eq('id', submissionId)
        .eq('reporter_id', _userId)
        .maybeSingle()
        .timeout(_timeout);
    if (existing != null) return _decode(existing);

    final isRoom = report.type == 'Phòng máy';
    final assetId = report.assetId;
    if (assetId == null) {
      throw const FormatException('Vui lòng tải lại danh mục và chọn tài sản.');
    }
    final assetQuery = _client
        .from(isRoom ? 'rooms' : 'equipment')
        .select('id')
        .eq('id', assetId);
    final asset =
        await (isRoom
                ? assetQuery.eq('is_archived', false)
                : assetQuery.isFilter('room_id', null))
            .single()
            .timeout(_timeout);
    if (report.photos.isNotEmpty) {
      final png = await _encodePhoto(report.photos.single);
      await _images
          .uploadBinary(
            _imagePath(submissionId),
            png,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          )
          .timeout(_timeout);
    }
    final row = await _client
        .from('incident_reports')
        .insert({
          'id': submissionId,
          if (isRoom) 'room_id': asset['id'] else 'equipment_id': asset['id'],
          'title': report.title,
          'description': report.description,
          'course_section': report.course.isEmpty ? null : report.course,
          'needs_support': report.needsSupport,
          'occurred_at': report.occurredAt.toUtc().toIso8601String(),
          'has_photo': report.photos.isNotEmpty,
        })
        .select(_fields)
        .single()
        .timeout(_timeout);
    return _decode(row);
  }

  Future<StoredIncidentReport> cancel(String id) async {
    _checkSession();
    final row = await _client
        .from('incident_reports')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('reporter_id', _userId)
        .eq('status', 'open')
        .isFilter('approved_at', null)
        .select(_fields)
        .single()
        .timeout(_timeout);
    return _decode(row);
  }

  Future<Uint8List> loadPhoto(String id) {
    _checkSession();
    return _images.download(_imagePath(id)).timeout(_timeout);
  }

  Future<Uint8List> _encodePhoto(Uint8List original) async {
    final codec = await ui.instantiateImageCodec(
      original,
      targetWidth: 1200,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null || data.lengthInBytes > 5 * 1024 * 1024) {
          throw const FormatException('Ảnh vượt quá giới hạn 5 MB.');
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  StoredIncidentReport _decode(Map<String, dynamic> row) {
    final room = row['rooms'] as Map<String, dynamic>?;
    final equipment = row['equipment'] as Map<String, dynamic>?;
    return (
      id: row['id'] as String,
      report: (
        id: row['report_number'] as int,
        title: row['title'] as String,
        description: row['description'] as String? ?? '',
        type: row['room_id'] != null ? 'Phòng máy' : 'Thiết bị',
        assetId: (row['room_id'] ?? row['equipment_id']) as String?,
        asset: (room ?? equipment)?['name'] as String? ?? 'Tài sản',
        course: row['course_section'] as String? ?? '',
        needsSupport: row['needs_support'] == true,
        occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
        submittedAt: DateTime.parse(row['created_at'] as String).toLocal(),
        photos: const <Uint8List>[],
      ),
      status: switch (row['status']) {
        'open' =>
          row['approved_at'] == null
              ? IncidentStatus.pending
              : IncidentStatus.approved,
        'in_progress' => IncidentStatus.inProgress,
        'resolved' => IncidentStatus.completed,
        'cancelled' => IncidentStatus.cancelled,
        _ => throw const FormatException('Trạng thái báo cáo không hợp lệ.'),
      },
      updatedAt: DateTime.tryParse(row['status_updated_at'] as String? ?? '')
          ?.toLocal(),
      hasPhoto: row['has_photo'] == true,
    );
  }
}
