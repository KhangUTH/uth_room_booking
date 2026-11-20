import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileContactStore {
  ProfileContactStore(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;
  static const _timeout = Duration(seconds: 10);

  Future<String?> changePassword(String current, String replacement) async {
    if (_client.auth.currentUser?.id != _userId) {
      return 'Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.';
    }
    try {
      await _client.auth
          .updateUser(
            UserAttributes(currentPassword: current, password: replacement),
          )
          .timeout(_timeout);
      return null;
    } on AuthException catch (error) {
      return switch (error.code) {
        'invalid_credentials' ||
        'current_password_invalid' => 'Mật khẩu hiện tại không đúng.',
        'weak_password' => 'Mật khẩu mới chưa đáp ứng yêu cầu bảo mật.',
        'same_password' => 'Mật khẩu mới phải khác mật khẩu hiện tại.',
        'reauthentication_needed' =>
          'Vui lòng đăng nhập lại rồi thử đổi mật khẩu.',
        _ => 'Không thể đổi mật khẩu. Vui lòng thử lại.',
      };
    } catch (_) {
      return 'Chưa xác nhận được kết quả. Hãy kiểm tra kết nối và thử lại.';
    }
  }

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
