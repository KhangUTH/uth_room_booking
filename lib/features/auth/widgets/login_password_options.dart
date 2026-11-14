import 'package:flutter/material.dart';

class LoginPasswordOptions extends StatefulWidget {
  const LoginPasswordOptions({super.key});

  @override
  State<LoginPasswordOptions> createState() => _LoginPasswordOptionsState();
}

class _LoginPasswordOptionsState extends State<LoginPasswordOptions> {
  bool _remember = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
          title: const Text('Nhớ mật khẩu', style: TextStyle(fontSize: 12)),
          value: _remember,
          onChanged: (value) {
            setState(() => _remember = value ?? false);
            if (_remember) {
              _showMessage('Bản demo chưa lưu mật khẩu.');
            }
          },
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showMessage(
              'Khôi phục mật khẩu sẽ khả dụng khi kết nối hệ thống đăng nhập.',
            ),
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
