import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RememberedSessionStorage extends LocalStorage {
  RememberedSessionStorage(String projectHost)
    : _legacyKey = 'sb-${projectHost.split('.').first}-auth-token',
      _key = 'uth-session-$projectHost';

  final String _legacyKey;
  final String _key;
  final _secure = const FlutterSecureStorage();
  Future<void> _pending = Future.value();
  bool _remember = false;
  bool _needsRemoval = false;
  String? _initialSession;

  @override
  Future<void> initialize() async {
    final legacy = SharedPreferencesLocalStorage(persistSessionKey: _legacyKey);
    await legacy.initialize();
    await legacy.removePersistedSession();
    try {
      _initialSession = await _secure.read(key: _key);
      _remember = _initialSession != null;
      _needsRemoval = _remember;
    } on PlatformException {
      _remember = false;
    }
  }

  @override
  Future<bool> hasAccessToken() async => _initialSession != null;

  @override
  Future<String?> accessToken() async => _initialSession;

  Future<void> _queue(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> remember(Session session) async {
    _remember = true;
    _needsRemoval = true;
    await _queue(() => _secure.write(key: _key, value: jsonEncode(session)));
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (!_remember) return;
    try {
      await _queue(() => _secure.write(key: _key, value: persistSessionString));
    } on PlatformException {
      // The SDK invokes this callback in the background during token refresh.
    }
  }

  @override
  Future<void> removePersistedSession() async {
    _remember = false;
    _initialSession = null;
    if (_needsRemoval) {
      await _queue(() async {
        await _secure.delete(key: _key);
        _needsRemoval = false;
      });
    }
  }
}
