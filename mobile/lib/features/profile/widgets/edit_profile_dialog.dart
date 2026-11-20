import 'package:flutter/material.dart';

class ProfileDialogTitle extends StatelessWidget {
  const ProfileDialogTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title)),
      const SizedBox(width: 10),
      Image.asset(
        'assets/images/logo/logo.jpg',
        width: 64,
        height: 24,
        fit: BoxFit.contain,
        semanticLabel: 'Logo UTH',
      ),
    ],
  );
}

Future<bool?> showChangePasswordDialog(
  BuildContext context,
  Future<String?> Function(String current, String replacement) changePassword,
) {
  const labels = ['Mật khẩu hiện tại', 'Mật khẩu mới', 'Xác nhận mật khẩu'];
  final passwords = ['', '', ''];
  final obscured = List.filled(labels.length, true);
  bool saving = false;
  String? error;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => PopScope(
        canPop: !saving,
        child: AlertDialog(
          title: const ProfileDialogTitle('Đổi mật khẩu'),
          constraints: const BoxConstraints.tightFor(width: 480),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < labels.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: labels[index],
                      suffixIcon: IconButton(
                        tooltip: obscured[index]
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: saving
                            ? null
                            : () => refresh(
                                () => obscured[index] = !obscured[index],
                              ),
                        icon: Icon(
                          obscured[index]
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                      ),
                    ),
                    enabled: !saving,
                    obscureText: obscured[index],
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (value) {
                      passwords[index] = value;
                      if (error != null) refresh(() => error = null);
                    },
                  ),
                ),
              if (error case final message?)
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (saving) return;
                      final validationError = switch (passwords) {
                        ['', _, _] ||
                        [_, '', _] ||
                        [_, _, ''] => 'Vui lòng nhập đủ ba ô mật khẩu.',
                        [_, final next, final confirmed]
                            when next != confirmed =>
                          'Xác nhận mật khẩu chưa khớp.',
                        [final current, final next, _] when current == next =>
                          'Mật khẩu mới phải khác mật khẩu hiện tại.',
                        _ => null,
                      };
                      if (validationError != null) {
                        refresh(() => error = validationError);
                        return;
                      }
                      FocusManager.instance.primaryFocus?.unfocus();
                      refresh(() {
                        saving = true;
                        error = null;
                      });
                      final failure = await changePassword(
                        passwords[0],
                        passwords[1],
                      );
                      if (!context.mounted) return;
                      if (failure == null) {
                        Navigator.pop(context, true);
                      } else {
                        refresh(() {
                          error = failure;
                          saving = false;
                        });
                      }
                    },
              child: Text(saving ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ),
    ),
  );
}

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
          title: const ProfileDialogTitle('Chỉnh sửa thông tin'),
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
