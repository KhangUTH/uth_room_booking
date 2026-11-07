import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

import '../models/support_request.dart';
import '../widgets/support_widgets.dart';

class ContactSupportPage extends StatefulWidget {
  final String name;
  final ValueChanged<SupportRequest> onSave;
  const ContactSupportPage({
    super.key,
    required this.name,
    required this.onSave,
  });

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  final _email = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      SupportRequest(
        category: 'Liên hệ hỗ trợ',
        fields: {
          'Họ và tên': _name.text.trim(),
          'Email': _email.text.trim(),
          'Nội dung': _message.text.trim(),
        },
      ),
    );
    showSupportSaved(context);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Thông tin liên hệ (mẫu)',
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      SupportPanel(
        child: Column(
          children: [
            _contact(Icons.mail_outline, 'Email', 'LIC@UT.EDU.VN'),
            _contact(
              Icons.phone_in_talk_outlined,
              'Số điện thoại',
              '(028) 35 126 169',
            ),
            _contact(
              Icons.location_on_outlined,
              'Địa chỉ',
              'Cơ sở 3: Số 70 đường Tô Ký, P. Trung Mỹ Tây, TP. HCM',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Gửi tin nhắn hỗ trợ',
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      SupportPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SupportField(
                label: 'Họ và tên',
                child: TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    hintText: 'Nhập họ và tên…',
                  ),
                  validator: requiredSupportText,
                ),
              ),
              SupportField(
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'Nhập email…'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(value.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
              SupportField(
                label: 'Nội dung cần hỗ trợ',
                child: TextFormField(
                  controller: _message,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nhập nội dung cần hỗ trợ…',
                  ),
                  validator: requiredSupportText,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Gửi liên hệ'),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _contact(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF4DB6B8),
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SelectableText(
                value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
