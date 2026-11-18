import 'package:flutter/material.dart';

Future<({String email, String phone})?> showEditProfileDialog(
  BuildContext context, {
  required String initialEmail,
  required String initialPhone,
  bool emailReadOnly = false,
  Future<void> Function(String)? onSavePhone,
}) {
  var email = initialEmail;
  var phone = initialPhone;
  var saving = false;
  String? error;
  return showDialog<({String email, String phone})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => PopScope(
        canPop: !saving,
        child: AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
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
                readOnly: saving,
                maxLength: 32,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  errorText: error,
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  phone = value;
                  if (error != null) refresh(() => error = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final changes = (
                        email: email.trim(),
                        phone: phone.trim(),
                      );
                      if (onSavePhone != null &&
                          changes.phone != initialPhone) {
                        refresh(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await onSavePhone(changes.phone);
                        } catch (_) {
                          if (context.mounted) {
                            refresh(() {
                              saving = false;
                              error = 'Không lưu được. Vui lòng thử lại.';
                            });
                          }
                          return;
                        }
                      }
                      if (context.mounted) Navigator.pop(context, changes);
                    },
              child: Text(saving ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ),
    ),
  );
}
