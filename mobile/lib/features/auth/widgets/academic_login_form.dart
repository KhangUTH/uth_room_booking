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
    required this.keepSignedIn,
    required this.onKeepSignedInChanged,
    this.submitting = false,
    this.credentialsError,
    this.onCredentialsChanged,
    this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController idController;
  final TextEditingController passwordController;
  final bool isStudent;
  final VoidCallback? onLogin;
  final bool keepSignedIn;
  final ValueChanged<bool> onKeepSignedInChanged;
  final bool submitting;
  final String? credentialsError;
  final VoidCallback? onCredentialsChanged;
  final VoidCallback? onForgotPassword;

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
          _label(
            widget.isStudent ? 'Mã sinh viên / Email' : 'Mã giảng viên / Email',
          ),
          TextFormField(
            controller: widget.idController,
            onChanged: (_) => widget.onCredentialsChanged?.call(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: widget.isStudent
                  ? 'Nhập mã sinh viên / Email'
                  : 'Nhập mã giảng viên / Email',
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
            onChanged: (_) => widget.onCredentialsChanged?.call(),
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onLogin?.call(),
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
          if (widget.credentialsError case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          LoginPasswordOptions(
            onForgotPassword: widget.onForgotPassword,
            keepSignedIn: widget.keepSignedIn,
            onKeepSignedInChanged: widget.submitting
                ? null
                : widget.onKeepSignedInChanged,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onLogin,
              child: Text(
                widget.submitting ? 'Đang đăng nhập…' : 'Đăng nhập',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
