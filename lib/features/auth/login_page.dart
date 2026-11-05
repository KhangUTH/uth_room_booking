import "package:flutter/material.dart";
import "package:uth_room_booking/homepage.dart";

enum UserRole { student, teacher }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _teal = Color(0xFF0E7C7B);
  static const _bg = Color(0xFFF1F5F4);

  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  UserRole _role = UserRole.student;
  bool _remember = false;
  bool _obscure = true;

  bool get _isStudent => _role == UserRole.student;

  @override
  void dispose() {
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
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 12),
                  _buildCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'UTH • Kết nối tri thức, kiến tạo tương lai',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {}, // TODO: cổng dành cho kỹ thuật viên
                    child: const Text(
                      'Cổng dành cho kỹ thuật viên',
                      style: TextStyle(color: _teal, fontSize: 12),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/splash/logo.jpg',
          height: 40,
          errorBuilder: (_, __, ___) => const Text(
            'UTH',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: _teal),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Trường Đại học Giao Thông Vận Tải\nThành phố Hồ Chí Minh',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildRoleTabs(),
          ),
          _buildIllustration(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabs() {
    Widget tab(String label, UserRole role) {
      final selected = _role == role;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchRole(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? _teal : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab('Sinh viên', UserRole.student),
          tab('Giảng viên', UserRole.teacher),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    final path = _isStudent
        ? 'assets/images/login_student.png'
        : 'assets/images/login_teacher.png';

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFD7EBE8),
          child: Icon(
            _isStudent ? Icons.school : Icons.person_pin,
            size: 64,
            color: _teal,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đăng nhập dành cho',
              style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(
            _isStudent ? 'Sinh viên' : 'Giảng viên',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            _isStudent
                ? 'Tài khoản học tập và quản lý học vụ'
                : 'Tài khoản giảng dạy và quản lý lớp học',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _label(_isStudent ? 'Mã sinh viên' : 'Mã giáo viên'),
          TextFormField(
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              _isStudent ? 'Nhập mã sinh viên' : 'Nhập mã giáo viên',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (_isStudent
                    ? 'Vui lòng nhập mã sinh viên'
                    : 'Vui lòng nhập mã giáo viên')
                : null,
          ),
          const SizedBox(height: 12),
          _label('Mật khẩu'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: _inputDecoration('Nhập mật khẩu').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Vui lòng nhập mật khẩu'
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _remember,
                  activeColor: _teal,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Nhớ mật khẩu', style: TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () {}, // TODO: quên mật khẩu
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Quên mật khẩu?',
                    style: TextStyle(color: _teal, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Đăng nhập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Đăng nhập bằng tài khoản do trường cấp',
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal),
        ),
      );
}