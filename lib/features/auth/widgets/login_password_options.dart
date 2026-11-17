import 'package:flutter/material.dart';

class LoginPasswordOptions extends StatefulWidget {
  const LoginPasswordOptions({
    super.key,
    required this.keepSignedIn,
    required this.onKeepSignedInChanged,
  });

  final bool keepSignedIn;
  final ValueChanged<bool>? onKeepSignedInChanged;

  @override
  State<LoginPasswordOptions> createState() => _LoginPasswordOptionsState();
}

class _LoginPasswordOptionsState extends State<LoginPasswordOptions> {
  bool _noticeVisible = false;

  Future<void> _showRecoveryNotice() async {
    if (_noticeVisible) return;
    _noticeVisible = true;
    try {
      await ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(content: Text('Tính năng đang phát triển.')),
          )
          .closed;
    } finally {
      _noticeVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          horizontalTitleGap: 4,
          visualDensity: VisualDensity.compact,
          checkboxScaleFactor: .9,
          dense: true,
          title: const Text(
            'Ghi nhớ đăng nhập',
            style: TextStyle(fontSize: 12),
          ),
          value: widget.keepSignedIn,
          onChanged: widget.onKeepSignedInChanged == null
              ? null
              : (value) => widget.onKeepSignedInChanged?.call(value ?? false),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showRecoveryNotice,
            child: const Text(
              'Quên mật khẩu?',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}
