import 'login_password_options.dart';

import "package:flutter/material.dart";
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uth_room_booking/core/router/app_route.dart';
import "package:uth_room_booking/theme/app_colors.dart";

Future<HomeRouteArgs?> showTechnicianLoginSheet(
  BuildContext context, {
  required Future<HomeRouteArgs> Function(String, String, bool) authenticate,
  VoidCallback? onForgotPassword,
}) {
  return showModalBottomSheet<HomeRouteArgs>(
    context: context,
    isScrollControlled: true, // để sheet đẩy lên theo bàn phím
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.white,
    clipBehavior: Clip.antiAlias,
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => TechnicianLoginSheet(
      authenticate: authenticate,
      onForgotPassword: onForgotPassword,
    ),
  );
}

class TechnicianLoginSheet extends StatefulWidget {
  const TechnicianLoginSheet({
    super.key,
    required this.authenticate,
    this.onForgotPassword,
  });

  final Future<HomeRouteArgs> Function(String, String, bool) authenticate;
  final VoidCallback? onForgotPassword;

  @override
  State<TechnicianLoginSheet> createState() => _TechnicianLoginSheetState();
}

class _TechnicianLoginSheetState extends State<TechnicianLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  bool _keepSignedIn = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting ||
        ModalRoute.of(context)?.isCurrent == false ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final profile = await widget.authenticate(
        _idCtrl.text.trim(),
        _passCtrl.text,
        _keepSignedIn,
      );
      if (mounted) Navigator.pop(context, profile);
    } on AuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'invalid_credentials'
              ? 'Thông tin đăng nhập hoặc mật khẩu không đúng.'
              : error.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể đăng nhập. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đẩy nội dung lên khi bàn phím mở.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return PopScope<HomeRouteArgs>(
      canPop: !_submitting,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: keyboard),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: 'Đóng đăng nhập kỹ thuật viên',
                  onPressed: _submitting
                      ? null
                      : () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              _buildLogo(),
              const SizedBox(height: 18),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  // ==== LOGO ====
  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo/logo.jpg',
            height: 33,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, size: 33, color: AppColors.primary),
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
      ),
    );
  }

  // ==== FORM ====
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
          const Text(
            'Kỹ thuật viên',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tài khoản hỗ trợ kỹ thuật và quản lý hệ thống',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          _label('Mã nhân viên / Email'),
          TextFormField(
            controller: _idCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: 'Nhập mã nhân viên / Email'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập mã nhân viên hoặc email'
                : null,
          ),
          const SizedBox(height: 14),
          _label('Mật khẩu'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
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
          LoginPasswordOptions(
            onForgotPassword: _submitting ? null : widget.onForgotPassword,
            keepSignedIn: _keepSignedIn,
            onKeepSignedInChanged: _submitting
                ? null
                : (value) => setState(() => _keepSignedIn = value),
          ),
          if (_error case final message?)
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(
                _submitting ? 'Đang đăng nhập…' : 'Đăng nhập',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
