import "package:flutter/material.dart";
import "package:uth_room_booking/homepage.dart";
import "package:uth_room_booking/theme/app_colors.dart";
import "package:uth_room_booking/features/auth/technician_login_sheet.dart";

enum UserRole { student, teacher }

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
  bool _remember = false;
  bool _obscure = true;

  bool get _isStudent => _role == UserRole.student;

  Future<void> _openTechnicianLogin() async {
    final id = await showTechnicianLoginSheet(context);
    if (id == null || !mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(name: 'Kỹ thuật viên demo', id: id),
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
  // Sau này thay đoạn này bằng gọi API / Firebase Auth.
  void _login() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: _isStudent ? 'Sinh viên demo' : 'Giảng viên demo',
          id: _idCtrl.text.trim(),
        ),
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
                    onPressed: _openTechnicianLogin, // TODO: cổng dành cho kỹ thuật viên
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
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  // ==== TABS ====
  Widget _buildRoleTabs() {
    Widget tab(String label, UserRole role) {
      final selected = _role == role;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _switchRole(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          tab('Sinh viên', UserRole.student),
          tab('Giảng viên', UserRole.teacher),
        ],
      ),
    );
  }

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

  // ---------------------------------------------------------------- FORM
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng nhập dành cho',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            _isStudent ? 'Sinh viên' : 'Giảng viên',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isStudent
                ? 'Tài khoản học tập và quản lý học vụ'
                : 'Tài khoản giảng dạy và quản lý lớp học',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          _label(_isStudent ? 'Mã sinh viên' : 'Mã giáo viên'),
          TextFormField(
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: _isStudent ? 'Nhập mã sinh viên' : 'Nhập mã giáo viên',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (_isStudent
                      ? 'Vui lòng nhập mã sinh viên'
                      : 'Vui lòng nhập mã giáo viên')
                : null,
          ),
          const SizedBox(height: 14),
          _label('Mật khẩu'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
          ),
          const SizedBox(height: 12),
          // Hàng 1: Nhớ mật khẩu
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _remember,
                  side: const BorderSide(color: Color(0xFFB8C4C3), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nhớ mật khẩu',
                style: TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
            ],
          ),
          // Hàng 2: Quên mật khẩu (căn phải)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {}, // TODO: quên mật khẩu
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _login,
              child: const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Đăng nhập bằng tài khoản do trường cấp',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    ),
  );
}
