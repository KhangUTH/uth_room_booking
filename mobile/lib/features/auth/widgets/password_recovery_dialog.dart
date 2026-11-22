import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_colors.dart';
import '../data/auth_store.dart';

Future<void> showPasswordRecoveryDialog(
  BuildContext context,
  PasswordRecovery? recovery,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  try {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PasswordRecoveryDialog(recovery: recovery),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Đã đặt lại mật khẩu. Hãy đăng nhập lại.'),
          ),
        );
    }
  } finally {
    await recovery?.close();
  }
}

enum _RecoveryStep { email, code, password }

class _PasswordRecoveryDialog extends StatefulWidget {
  const _PasswordRecoveryDialog({required this.recovery});

  final PasswordRecovery? recovery;

  @override
  State<_PasswordRecoveryDialog> createState() =>
      _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<_PasswordRecoveryDialog> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _codePattern = RegExp(r'^\d{6,10}$');
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _visiblePasswords = <TextEditingController>{};
  _RecoveryStep _step = _RecoveryStep.email;
  bool _busy = false;
  String? _error;
  Timer? _resendTimer;
  int _seconds = 0;

  String get _address => _email.text.trim();

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _startCooldown() {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    _resendTimer?.cancel();
    _seconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = deadline.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) timer.cancel();
      setState(() => _seconds = remaining > 0 ? remaining : 0);
    });
  }

  Future<void> _sendCode(PasswordRecovery recovery) async {
    try {
      await recovery.sendCode(_address);
    } on AuthException catch (error) {
      if (error.code != 'email_address_not_authorized' &&
          error.code != 'user_not_found') {
        rethrow;
      }
    }
    if (!mounted) return;
    _code.clear();
    setState(() {
      _step = _RecoveryStep.code;
      _startCooldown();
    });
  }

  Future<void> _submit({bool resend = false}) async {
    final recovery = widget.recovery;
    if (recovery == null || _busy || (resend && _seconds > 0)) return;
    if (!resend && !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (resend || _step == _RecoveryStep.email) {
        await _sendCode(recovery);
      } else if (_step == _RecoveryStep.code) {
        await recovery.verifyCode(_address, _code.text);
        if (mounted) setState(() => _step = _RecoveryStep.password);
      } else {
        await recovery.updatePassword(_password.text);
        if (!mounted) return;
        setState(() => _busy = false);
        Navigator.pop(context, true);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'otp_expired' || 'invalid_credentials' =>
            'Mã không hợp lệ hoặc đã hết hạn. Hãy kiểm tra hoặc gửi lại mã.',
          'over_email_send_rate_limit' || 'over_request_rate_limit' =>
            'Bạn đã yêu cầu quá nhiều lần. Vui lòng chờ rồi thử lại.',
          'weak_password' => 'Mật khẩu mới chưa đạt yêu cầu bảo mật.',
          'same_password' => 'Mật khẩu mới phải khác mật khẩu cũ.',
          _ => 'Chưa thể tiếp tục. Vui lòng thử lại.',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa thể xác nhận kết quả. Hãy kiểm tra kết nối.',
        );
      }
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  List<Widget> _fields() => switch (_step) {
    _RecoveryStep.email => [
      const Text('Nhập email đã đăng ký với UTH Lab để khôi phục mật khẩu.'),
      const SizedBox(height: 12),
      TextFormField(
        key: const ValueKey('recovery-email'),
        controller: _email,
        enabled: !_busy,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          labelText: 'Email tài khoản',
          prefixIcon: Icon(Icons.mail_outline, color: AppColors.primary),
        ),
        validator: (value) => _emailPattern.hasMatch(value?.trim() ?? '')
            ? null
            : 'Vui lòng nhập email hợp lệ.',
      ),
    ],
    _RecoveryStep.code => [
      Text('Nếu email $_address đã đăng ký, bạn sẽ nhận được mã khôi phục.'),
      const SizedBox(height: 12),
      TextFormField(
        key: const ValueKey('recovery-code'),
        controller: _code,
        enabled: !_busy,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Mã xác minh'),
        validator: (value) => _codePattern.hasMatch(value ?? '')
            ? null
            : 'Vui lòng nhập đầy đủ mã nhận được.',
      ),
      TextButton(
        onPressed: _busy || _seconds > 0 ? null : () => _submit(resend: true),
        child: Text(
          _seconds > 0 ? 'Gửi lại mã ($_seconds giây)' : 'Gửi lại mã',
        ),
      ),
    ],
    _RecoveryStep.password => [
      _passwordField(
        'Mật khẩu mới',
        _password,
        (value) => value == null || value.isEmpty
            ? 'Vui lòng nhập mật khẩu mới.'
            : null,
      ),
      const SizedBox(height: 12),
      _passwordField(
        'Xác nhận mật khẩu',
        _confirmation,
        (value) =>
            value == _password.text ? null : 'Xác nhận mật khẩu chưa khớp.',
      ),
    ],
  };

  Widget _passwordField(
    String label,
    TextEditingController controller,
    FormFieldValidator<String> validator,
  ) {
    final visible = _visiblePasswords.contains(controller);
    return TextFormField(
      key: ValueKey(label),
      controller: controller,
      enabled: !_busy,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
          onPressed: _busy
              ? null
              : () => setState(() {
                  if (!_visiblePasswords.remove(controller)) {
                    _visiblePasswords.add(controller);
                  }
                }),
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: const BoxConstraints.tightFor(width: 420),
      scrollable: true,
      title: Column(
        children: [
          Image.asset(
            'assets/images/logo/logo.jpg',
            height: 36,
            fit: BoxFit.contain,
            semanticLabel: 'Logo UTH',
          ),
          const SizedBox(height: 12),
          Text(
            _step == _RecoveryStep.password
                ? 'Đặt mật khẩu mới'
                : 'Quên mật khẩu',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._fields(),
            if (widget.recovery == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Chưa có kết nối xác thực để gửi mã.'),
              ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          onPressed: _busy || widget.recovery == null ? null : _submit,
          child: Text(
            _busy
                ? 'Đang xử lý…'
                : switch (_step) {
                    _RecoveryStep.email => 'Gửi mã',
                    _RecoveryStep.code => 'Xác minh',
                    _RecoveryStep.password => 'Lưu mật khẩu',
                  },
          ),
        ),
      ],
    ),
  );
}
