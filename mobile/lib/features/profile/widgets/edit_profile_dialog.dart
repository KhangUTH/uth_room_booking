import 'package:flutter/material.dart';

Future<({String email, String phone})?> showEditProfileDialog(
  BuildContext context, {
  required String initialEmail,
  required String initialPhone,
  bool emailReadOnly = false,
}) {
  var email = initialEmail;
  var phone = initialPhone;
  return showDialog<({String email, String phone})>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chỉnh sửa thông tin'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      constraints: const BoxConstraints.tightFor(width: 480),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          TextFormField(
            initialValue: initialEmail,
            readOnly: emailReadOnly,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (value) => email = value,
          ),
          TextFormField(
            initialValue: initialPhone,
            decoration: const InputDecoration(labelText: 'Số điện thoại'),
            keyboardType: TextInputType.phone,
            onChanged: (value) => phone = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (
            email: email.trim(),
            phone: phone.trim(),
          )),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}
