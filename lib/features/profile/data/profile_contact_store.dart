import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileContactStore {
  ProfileContactStore(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;
  static const _timeout = Duration(seconds: 10);

  Future<String> loadPhone() async {
    final row = await _client
        .from('profiles')
        .select('phone')
        .eq('id', _userId)
        .single()
        .timeout(_timeout);
    return row['phone'] as String? ?? '';
  }

  Future<void> savePhone(String phone) async {
    final value = phone.trim();
    await _client
        .from('profiles')
        .update({'phone': value.isEmpty ? null : value})
        .eq('id', _userId)
        .select('id')
        .single()
        .timeout(_timeout);
  }
}
