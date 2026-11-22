import 'package:flutter/material.dart';

class LoginPasswordOptions extends StatelessWidget {
  const LoginPasswordOptions({
    super.key,
    required this.keepSignedIn,
    required this.onKeepSignedInChanged,
    this.onForgotPassword,
  });

  final bool keepSignedIn;
  final ValueChanged<bool>? onKeepSignedInChanged;
  final VoidCallback? onForgotPassword;

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
          value: keepSignedIn,
          onChanged: onKeepSignedInChanged == null
              ? null
              : (value) => onKeepSignedInChanged?.call(value ?? false),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onForgotPassword,
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
