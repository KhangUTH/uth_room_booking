import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_route.dart';
import '../models/user_role.dart';
import 'remembered_session_storage.dart';

/// Uses a separate in-memory Auth client so OTP verification cannot open Home.
class PasswordRecovery {
  PasswordRecovery(SupabaseClient client, {http.Client? httpClient})
    : _auth = GoTrueClient(
        url: client.rest.url.replaceFirst(RegExp(r'/rest/v1/?$'), '/auth/v1'),
        headers: {
          'apikey': client.auth.headers['apikey']!,
          'Authorization': 'Bearer ${client.auth.headers['apikey']!}',
        },
        autoRefreshToken: false,
        httpClient: httpClient,
        flowType: AuthFlowType.implicit,
      );

  final GoTrueClient _auth;
  static const _timeout = Duration(seconds: 15);

  Future<void> sendCode(String email) =>
      _auth.resetPasswordForEmail(email).timeout(_timeout);

  Future<void> verifyCode(String email, String code) async {
    final response = await _auth
        .verifyOTP(email: email, token: code, type: OtpType.recovery)
        .timeout(_timeout);
    if (response.session == null) {
      throw const AuthException('Missing recovery session');
    }
  }

  Future<void> updatePassword(String password) async {
    if (_auth.currentSession == null) {
      throw StateError('Missing recovery session');
    }
    await _auth
        .updateUser(UserAttributes(password: password))
        .timeout(_timeout);
  }

  Future<void> close() async {
    try {
      if (_auth.currentSession != null) {
        await _auth.signOut(scope: SignOutScope.local).timeout(_timeout);
      }
    } catch (_) {
      // The isolated session is discarded when the dialog closes.
    } finally {
      _auth.dispose();
    }
  }
}

Future<void> signOutFromApp(
  SupabaseClient client, {
  RememberedSessionStorage? sessionStorage,
}) async {
  await sessionStorage?.removePersistedSession();
  await _signOutLocally(client);
}

Future<void> _signOutLocally(SupabaseClient client) async {
  try {
    await client.auth.signOut(scope: SignOutScope.local);
  } catch (_) {
    // Supabase clears the local session before revoking it on the server.
    if (client.auth.currentSession != null) rethrow;
  }
}

Future<HomeRouteArgs?> restoreRememberedLogin(SupabaseClient client) async {
  try {
    final session = client.auth.currentSession;
    if (session == null) return null;
    final user = session.isExpired
        ? (await client.auth.refreshSession()).user
        : session.user;
    if (user == null || user.id != session.user.id) return null;
    final profile = await _readHomeProfile(client, user);
    return client.auth.currentUser?.id == user.id ? profile : null;
  } catch (_) {
    // Mất mạng hoặc phiên không hợp lệ thì trở lại màn xác thực.
    return null;
  }
}

Future<HomeRouteArgs> _readHomeProfile(
  SupabaseClient client,
  User user, {
  UserRole? expectedRole,
  String? enteredCode,
}) async {
  final profile = await client
      .from('profiles')
      .select(
        'full_name, student_code, lecturer_code, employee_code, role, is_active, faculty',
      )
      .eq('id', user.id)
      .maybeSingle();
  if (profile == null || profile['is_active'] != true) {
    throw const AuthException('Hồ sơ chưa được kích hoạt.');
  }
  final role = switch (profile['role']) {
    'student' => UserRole.student,
    'teacher' => UserRole.teacher,
    'technician' => UserRole.technician,
    _ => null,
  };
  if (role == null || (expectedRole != null && role != expectedRole)) {
    throw const AuthException('Vai trò tài khoản không khớp cổng đăng nhập.');
  }
  final codeColumn = switch (role) {
    UserRole.student => 'student_code',
    UserRole.teacher => 'lecturer_code',
    UserRole.technician => 'employee_code',
  };
  final code = (profile[codeColumn] as String?)?.trim();
  if (enteredCode != null && code?.toLowerCase() != enteredCode.toLowerCase()) {
    throw const AuthException(
      'Thông tin đăng nhập hoặc mật khẩu không đúng.',
      code: 'invalid_credentials',
    );
  }
  final name = (profile['full_name'] as String?)?.trim();
  final identifier = enteredCode ?? user.email ?? user.id;
  return (
    name: name == null || name.isEmpty ? identifier : name,
    id: code == null || code.isEmpty ? identifier : code,
    faculty: (profile['faculty'] as String?)?.trim(),
    role: role,
  );
}

Future<HomeRouteArgs> authenticateWithSupabase(
  SupabaseClient? client,
  RememberedSessionStorage? sessionStorage,
  String identifier,
  String password,
  UserRole expectedRole,
  bool keepSignedIn,
) async {
  const networkError = AuthException(
    'Không thể kết nối. Kiểm tra mạng rồi thử lại.',
  );
  try {
    return await _signIn(
      client,
      sessionStorage,
      identifier,
      password,
      expectedRole,
      keepSignedIn,
    );
  } on TimeoutException {
    throw networkError;
  } on http.ClientException {
    throw networkError;
  } on AuthRetryableFetchException catch (error) {
    if (error.statusCode == null) throw networkError;
    rethrow;
  }
}

Future<HomeRouteArgs> _signIn(
  SupabaseClient? client,
  RememberedSessionStorage? sessionStorage,
  String identifier,
  String password,
  UserRole expectedRole,
  bool keepSignedIn,
) async {
  if (client == null) {
    throw const AuthException('Chưa cấu hình hệ thống đăng nhập.');
  }
  await sessionStorage?.removePersistedSession();
  final isCode = !identifier.contains('@');
  final response = isCode
      ? await _signInByCode(client, identifier, password, expectedRole)
      : await client.auth.signInWithPassword(
          email: identifier,
          password: password,
        );
  try {
    final user = response.user;
    if (user == null) throw const AuthException('Không tìm thấy tài khoản.');
    final profile = await _readHomeProfile(
      client,
      user,
      expectedRole: expectedRole,
      enteredCode: isCode ? identifier : null,
    );
    final session = client.auth.currentSession;
    if (session == null || session.user.id != user.id) {
      throw const AuthException('Phiên đăng nhập đã hết hiệu lực.');
    }
    if (keepSignedIn) {
      await sessionStorage?.remember(session);
    }
    return profile;
  } catch (_) {
    await _signOutLocally(client);
    rethrow;
  }
}

Future<AuthResponse> _signInByCode(
  SupabaseClient client,
  String code,
  String password,
  UserRole role,
) async {
  try {
    final response = await client.functions.invoke(
      'sign-in-by-code',
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'password': password, 'role': role.name}),
    );
    final data = response.data;
    if (data is Map && data['session'] is Map) {
      return await client.auth.recoverSession(jsonEncode(data['session']));
    }
    if (data is Map && data['refresh_token'] is String) {
      return await client.auth.setSession(data['refresh_token'] as String);
    }
    throw const AuthException('Không thể đăng nhập. Vui lòng thử lại.');
  } on FunctionException catch (error) {
    final cause = error.details;
    if (cause is TimeoutException) throw cause;
    if (cause is http.ClientException) throw cause;
    if (error.status == 401) {
      throw const AuthException(
        'Thông tin đăng nhập hoặc mật khẩu không đúng.',
        code: 'invalid_credentials',
      );
    }
    if (error.status == 429) {
      throw const AuthException('Bạn thử đăng nhập lại sau ít phút.');
    }
    throw const AuthException('Không thể đăng nhập. Vui lòng thử lại.');
  }
}
