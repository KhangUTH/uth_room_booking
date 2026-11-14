import '../widgets/academic_login_form.dart';

import 'package:uth_room_booking/shared/widgets/pill_tabs.dart';
import "package:flutter/material.dart";
import 'package:uth_room_booking/core/router/app_route.dart';
import "package:uth_room_booking/theme/app_colors.dart";
import "package:uth_room_booking/features/auth/widgets/technician_login_sheet.dart";

import '../models/user_role.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  bool get _isStudent => _role == UserRole.student;

  Future<void> _openTechnicianLogin() async {
    final id = await showTechnicianLoginSheet(context);
    if (id == null || !mounted) return;
    Navigator.of(context).pushReplacementNamed<void, void>(
      AppRoute.home,
      arguments: (
        name: 'Kỹ thuật viên demo',
        id: id,
        role: UserRole.technician,
      ),
    );
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
    if (role == _role) return;
    setState(() {
      _role = role;
      _idCtrl.clear();
      _passCtrl.clear();
      _formKey.currentState?.reset();
    });
  }

  // DEMO: chưa có database, nhập gì cũng vào được (miễn không để trống).
  // Sau này thay đoạn này bằng Supabase Auth và vai trò từ backend.
  void _login() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pushReplacementNamed<void, void>(
      AppRoute.home,
      arguments: (
        name: _isStudent ? 'Sinh viên demo' : 'Giảng viên demo',
        id: _idCtrl.text.trim(),
        role: _role,
      ),
    );
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
              onLogin: _login,
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
