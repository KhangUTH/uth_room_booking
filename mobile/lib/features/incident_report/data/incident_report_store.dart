import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/images/encode_jpeg_photo.dart';
import '../models/incident_report.dart';

typedef StoredIncidentReport = ({
  String id,
  IncidentReport report,
  IncidentStatus status,
  DateTime? updatedAt,
  bool hasPhoto,
  bool canCancel,
});

class IncidentReportStore {
  IncidentReportStore(this._client, this._userId, {http.Client? uploadClient})
    : _postPhoto = uploadClient?.post ?? http.post;

  final SupabaseClient _client;
  final String _userId;
  final Future<http.Response> Function(
    Uri, {
    Map<String, String>? headers,
    Object? body,
  })
  _postPhoto;
  static const _imageBucket = 'incident-images';
  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 45);
  static const _fields =
      'id,report_number,title,description,status,created_at,'
      'course_section,needs_support,has_photo,status_updated_at,assigned_to,'
      'rooms(name),equipment(name)';

  String newSubmissionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  StorageFileApi get _images => _client.storage.from(_imageBucket);
  String _imagePath(String id) => '$_userId/${id.replaceAll('-', '')}.jpg';

  Future<List<StoredIncidentReport>> history() async {
    final rows = await _client
        .from('incident_reports')
        .select(_fields)
        .eq('reporter_id', _userId)
        .order('created_at', ascending: false)
        .order('report_number', ascending: false)
        .timeout(_timeout);
    return rows.map(_decode).toList();
  }

  Future<StoredIncidentReport?> reportById(String id) async {
    final row = await _client
        .from('incident_reports')
        .select(_fields)
        .eq('reporter_id', _userId)
        .eq('id', id)
        .maybeSingle()
        .timeout(_timeout);
    return row == null ? null : _decode(row);
  }

  Future<StoredIncidentReport> submit(
    String submissionId,
    IncidentReport report, {
    void Function(bool)? onPhotoUploadChanged,
  }) async {
    if (_client.auth.currentUser?.id != _userId) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    final existing = await _client
        .from('incident_reports')
        .select(_fields)
        .eq('id', submissionId)
        .eq('reporter_id', _userId)
        .maybeSingle()
        .timeout(_timeout);
    if (existing != null) return _decode(existing);

    final isRoom = report.type == 'Phòng máy';
    final assetQuery = _client
        .from(isRoom ? 'rooms' : 'equipment')
        .select('id')
        .eq('name', report.asset);
    final asset =
        await (isRoom
                ? assetQuery.eq('is_archived', false)
                : assetQuery.isFilter('room_id', null))
            .single()
            .timeout(_timeout);
    if (report.photos.isNotEmpty) {
      onPhotoUploadChanged?.call(true);
      try {
        await _uploadPhoto(submissionId, report.photos.single);
      } finally {
        onPhotoUploadChanged?.call(false);
      }
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
          'has_photo': report.photos.isNotEmpty,
        }, defaultToNull: false)
        .select(_fields)
        .single()
        .timeout(_timeout);
    return _decode(row);
  }

  Future<StoredIncidentReport> cancel(String id) async {
    final row = await _client
        .from('incident_reports')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('reporter_id', _userId)
        .eq('status', 'open')
        .isFilter('assigned_to', null)
        .select(_fields)
        .single()
        .timeout(_timeout);
    return _decode(row);
  }

  Future<Uint8List?> loadPhoto(String id) => loadEvidence(_client, id);

  static Future<Uint8List?> loadEvidence(
    SupabaseClient client,
    String id,
  ) async {
    final path = await client
        .rpc<String?>('incident_evidence_path', params: {'report_id': id})
        .timeout(_timeout);
    if (path == null) return null;
    return client.storage.from(_imageBucket).download(path).timeout(_timeout);
  }

  Future<void> _uploadPhoto(String id, Uint8List original) async {
    final path = _imagePath(id);
    final jpeg = await encodeJpegPhoto(original, maxEdge: incidentPhotoMaxEdge);
    var session = _client.auth.currentSession;
    if (session?.isExpired == true) {
      session = (await _client.auth.refreshSession().timeout(_timeout)).session;
    }
    if (session == null || session.user.id != _userId) {
      throw const FormatException('Phiên đăng nhập đã hết hạn.');
    }

    final storage = _client.storage;
    final uri = Uri.parse('${storage.url}/object/$_imageBucket/$path');
    final http.Response response;
    try {
      response = await _postPhoto(
        uri,
        headers: {
          ...storage.headers,
          'apikey': _client.auth.headers['apikey']!,
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'image/jpeg',
          'x-upsert': 'true',
        },
        body: jpeg,
      ).timeout(_uploadTimeout);
    } on Exception catch (error) {
      if (error is! http.ClientException && error is! TimeoutException) {
        rethrow;
      }
      // The server may have written the bytes before the connection dropped.
      if (await _matchesUploadedPhoto(path, jpeg)) {
        return;
      }
      if (error is TimeoutException) {
        throw FormatException(
          'Sau ${_uploadTimeout.inSeconds} giây vẫn chưa xác nhận được ảnh '
          'minh chứng. Vui lòng gửi lại.',
        );
      }
      throw const FormatException(
        'Kết nối bị gián đoạn khi tải ảnh minh chứng. Vui lòng gửi lại.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        'Supabase từ chối ảnh minh chứng (HTTP ${response.statusCode}).',
      );
    }
  }

  Future<bool> _matchesUploadedPhoto(String path, Uint8List expected) async {
    try {
      final uploaded = await _images.download(path).timeout(_timeout);
      return listEquals(uploaded, expected);
    } on Exception {
      return false;
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
        type: room != null ? 'Phòng máy' : 'Thiết bị',
        asset: (room ?? equipment)?['name'] as String? ?? 'Tài sản',
        course: row['course_section'] as String? ?? '',
        needsSupport: row['needs_support'] == true,
        submittedAt: DateTime.parse(row['created_at'] as String).toLocal(),
        photos: const <Uint8List>[],
      ),
      status: switch (row['status']) {
        'open' => IncidentStatus.pending,
        'in_progress' => IncidentStatus.inProgress,
        'resolved' => IncidentStatus.completed,
        'cancelled' => IncidentStatus.cancelled,
        _ => throw const FormatException('Trạng thái báo cáo không hợp lệ.'),
      },
      updatedAt: DateTime.tryParse(row['status_updated_at'] as String? ?? '')
          ?.toLocal(),
      hasPhoto: row['has_photo'] == true,
      canCancel: row['status'] == 'open' && row['assigned_to'] == null,
    );
  }
}
