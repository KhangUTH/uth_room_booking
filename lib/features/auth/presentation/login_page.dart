import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_route.dart';
import '../../../shared/widgets/pill_tabs.dart';
import '../../../theme/app_colors.dart';
import '../models/user_role.dart';
import '../widgets/academic_login_form.dart';
import '../widgets/technician_login_sheet.dart';

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.supabase, this.sessionStorage})
    : testAuthenticate = null;

  @visibleForTesting
  const LoginPage.withTestAuthentication({
    super.key,
    required Future<HomeRouteArgs> Function(String, String, UserRole)
    authenticate,
  }) : testAuthenticate = authenticate,
       supabase = null,
       sessionStorage = null;

  final SupabaseClient? supabase;
  final RememberedSessionStorage? sessionStorage;
  final Future<HomeRouteArgs> Function(String, String, UserRole)?
  testAuthenticate;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late final AnimationController _floatCtrl;

  UserRole _role = UserRole.student;
  bool _submitting = false;
  bool _keepSignedIn = false;
  String? _credentialsError;

  bool get _isStudent => _role == UserRole.student;

  Future<void> _openTechnicianLogin() async {
    if (_submitting) return;
    final profile = await showTechnicianLoginSheet(
      context,
      authenticate: (id, password, keepSignedIn) =>
          _authenticate(id, password, UserRole.technician, keepSignedIn),
    );
    if (profile != null && mounted) _openHome(profile);
  }

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _switchRole(UserRole role) {
    if (_submitting || role == _role) return;
    setState(() {
      _role = role;
      _credentialsError = null;
      _idCtrl.clear();
      _passCtrl.clear();
      _formKey.currentState?.reset();
    });
  }

  Future<HomeRouteArgs> _authenticate(
    String identifier,
    String password,
    UserRole expectedRole,
    bool keepSignedIn,
  ) async {
    final testAuthenticate = widget.testAuthenticate;
    if (testAuthenticate != null) {
      return testAuthenticate(identifier, password, expectedRole);
    }
    const networkError = AuthException(
      'Không thể kết nối. Kiểm tra mạng rồi thử lại.',
    );
    try {
      return await _signIn(identifier, password, expectedRole, keepSignedIn);
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
    String identifier,
    String password,
    UserRole expectedRole,
    bool keepSignedIn,
  ) async {
    final client = widget.supabase;
    if (client == null) {
      throw const AuthException('Chưa cấu hình hệ thống đăng nhập.');
    }
    await widget.sessionStorage?.removePersistedSession();
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
        await widget.sessionStorage?.remember(session);
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
        body: jsonEncode({
          'code': code,
          'password': password,
          'role': role.name,
        }),
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

  Future<void> _login() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _credentialsError = null;
    });
    try {
      final profile = await _authenticate(
        _idCtrl.text.trim(),
        _passCtrl.text,
        _role,
        _keepSignedIn,
      );
      if (mounted) _openHome(profile);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _credentialsError = error.code == 'invalid_credentials'
              ? 'Thông tin đăng nhập hoặc mật khẩu không đúng.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _credentialsError = 'Không thể đăng nhập. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openHome(HomeRouteArgs profile) {
    Navigator.of(context)
        .pushReplacementNamed<void, void>(AppRoute.home, arguments: profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 14),
                  _buildRoleTabs(),
                  const SizedBox(height: 12),
                  _buildCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'UTH • Kết nối tri thức, kiến tạo tương lai',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openTechnicianLogin,
                    child: const Text(
                      'Cổng dành cho kỹ thuật viên',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==== LOGO ====
  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo/logo.jpg',
          height: 33,
          fit: BoxFit.contain,
          // Làm nền trắng của file .jpg hòa vào màu nền trang.
          color: AppColors.background,
          colorBlendMode: BlendMode.multiply,
        ),
        const SizedBox(height: 8),
        const Text(
          'Trường Đại học Giao Thông Vận Tải\nThành phố Hồ Chí Minh',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ==== CARD ====
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIllustration(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: AcademicLoginForm(
              formKey: _formKey,
              idController: _idCtrl,
              passwordController: _passCtrl,
              isStudent: _isStudent,
              onLogin: _submitting ? null : _login,
              submitting: _submitting,
              keepSignedIn: _keepSignedIn,
              onKeepSignedInChanged: (value) =>
                  setState(() => _keepSignedIn = value),
              credentialsError: _credentialsError,
              onCredentialsChanged: () {
                if (_credentialsError != null) {
                  setState(() => _credentialsError = null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==== TABS ====
  Widget _buildRoleTabs() => PillTabs<UserRole>(
    options: const {
      UserRole.student: 'Sinh viên',
      UserRole.teacher: 'Giảng viên',
    },
    selected: _role,
    onSelected: _switchRole,
  );

  // ==== ẢNH + HIỆU ỨNG ====
  Widget _buildIllustration() {
    final path = _isStudent
        ? 'assets/images/illustrations/login_student.png'
        : 'assets/images/illustrations/login_teacher.png';

    final image = Image.asset(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFD7EBE8),
        child: Icon(
          _isStudent ? Icons.school : Icons.person_pin,
          size: 64,
          color: AppColors.primary,
        ),
      ),
    );

    return AspectRatio(
      aspectRatio: 2, // đúng tỷ lệ khung ảnh trong thiết kế
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(
              begin: Offset(_isStudent ? -0.25 : 0.25, 0),
              end: Offset.zero,
            ).animate(anim);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: AnimatedBuilder(
            key: ValueKey(_role),
            animation: _floatCtrl,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_floatCtrl.value);
              return Transform.scale(
                scale: 1.06 + 0.04 * t,
                child: Transform.translate(
                  offset: Offset(0, 3 - 6 * t),
                  child: child,
                ),
              );
            },
            child: image,
          ),
        ),
      ),
    );
  }
}
