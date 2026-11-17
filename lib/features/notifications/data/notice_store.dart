import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notice.dart';

class NoticeStore extends ChangeNotifier {
  NoticeStore(this._client);

  final SupabaseClient _client;
  final read = <int>{};
  final saved = <int>{};
  final _bookingIds = <int, String>{};
  List<AppNotice> notices = [];
  Timer? _timer;
  Future<void>? _refreshing;
  bool _disposed = false;
  bool loading = true;
  bool loadFailed = false;
  int _revision = 0;

  void start() {
    unawaited(refresh());
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(refresh()),
    );
  }

  String? bookingId(int noticeId) => _bookingIds[noticeId];

  Future<void> refresh() => _refreshing ??= _load().whenComplete(() {
    _refreshing = null;
  });

  Future<void> _load() async {
    final revision = _revision;
    try {
      final rows = await _client
          .from('app_notifications')
          .select('id,booking_id,title,message,created_at,is_read,is_saved')
          .order('id', ascending: false)
          .timeout(const Duration(seconds: 10));
      if (_disposed || revision != _revision) return;
      notices = [
        for (final row in rows)
          (
            id: row['id'] as int,
            icon: Icons.event_note_outlined,
            title: row['title'] as String,
            message: row['message'] as String,
            metadata: _formatDate(row['created_at'] as String),
            age: '',
          ),
      ];
      _bookingIds.clear();
      read.clear();
      saved.clear();
      for (final row in rows) {
        final id = row['id'] as int;
        if (row['booking_id'] case final String bookingId) {
          _bookingIds[id] = bookingId;
        }
        if (row['is_read'] == true) read.add(id);
        if (row['is_saved'] == true) saved.add(id);
      }
      loadFailed = false;
    } catch (_) {
      loadFailed = true;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  String _formatDate(String timestamp) {
    final time = DateTime.parse(timestamp)
        .toUtc()
        .add(const Duration(hours: 7));
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(time.hour)}:${pad(time.minute)} · ${pad(time.day)}/${pad(time.month)}/${time.year}';
  }

  Future<void> markRead(int id) async {
    if (read.contains(id)) return;
    await _update(id, 'is_read', true, read);
  }

  Future<void> setSaved(int id, bool value) =>
      _update(id, 'is_saved', value, saved);

  Future<void> deleteNotices(Set<int> ids) async {
    if (ids.isEmpty) return;
    await _client
        .rpc<void>(
          'delete_my_app_notifications',
          params: {'notice_ids': ids.toList()},
        )
        .timeout(const Duration(seconds: 10));
    if (_disposed) return;
    _revision++;
    notices = notices.where((notice) => !ids.contains(notice.id)).toList();
    read.removeAll(ids);
    saved.removeAll(ids);
    _bookingIds.removeWhere((id, _) => ids.contains(id));
    notifyListeners();
  }

  Future<void> _update(int id, String field, bool value, Set<int> flags) async {
    await _client
        .from('app_notifications')
        .update({field: value})
        .eq('id', id)
        .select('id')
        .single()
        .timeout(const Duration(seconds: 10));
    if (_disposed) return;
    _revision++;
    if (value) {
      flags.add(id);
    } else {
      flags.remove(id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
