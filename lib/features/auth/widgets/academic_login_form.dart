import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'login_password_options.dart';

class AcademicLoginForm extends StatefulWidget {
  const AcademicLoginForm({
    super.key,
    required this.formKey,
    required this.idController,
    required this.passwordController,
    required this.isStudent,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController idController;
  final TextEditingController passwordController;
  final bool isStudent;
  final VoidCallback onLogin;

  @override
  State<AcademicLoginForm> createState() => _AcademicLoginFormState();
}

class _AcademicLoginFormState extends State<AcademicLoginForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng nhập dành cho',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            widget.isStudent ? 'Sinh viên' : 'Giảng viên',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.isStudent
                ? 'Tài khoản học tập và quản lý học vụ'
                : 'Tài khoản giảng dạy và quản lý lớp học',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          _label(widget.isStudent ? 'Mã sinh viên' : 'Mã giáo viên'),
          TextFormField(
            controller: widget.idController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: widget.isStudent
                  ? 'Nhập mã sinh viên'
                  : 'Nhập mã giảng viên',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (widget.isStudent
                      ? 'Vui lòng nhập mã sinh viên'
                      : 'Vui lòng nhập mã giảng viên')
                : null,
          ),
          const SizedBox(height: 14),
          _label('Mật khẩu'),
          TextFormField(
            controller: widget.passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onLogin(),
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
          const LoginPasswordOptions(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onLogin,
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
