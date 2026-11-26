import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class ChatIncidentDraftDialog extends StatefulWidget {
  const ChatIncidentDraftDialog({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ChatIncidentDraftDialog> createState() =>
      _ChatIncidentDraftDialogState();
}

class _ChatIncidentDraftDialogState extends State<ChatIncidentDraftDialog> {
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Theme.of(context).colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    title: const Text('Kiểm tra báo cáo mẫu'),
    scrollable: true,
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Phòng hoặc thiết bị'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nhập phòng hoặc thiết bị'
                : null,
          ),
          TextFormField(
            initialValue: widget.message.text,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Mô tả'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nhập mô tả sự cố'
                : null,
          ),
          if (widget.message.image case final image?)
            Image.memory(image, height: 90),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState?.validate() == true) {
            Navigator.pop(context, true);
          }
        },
        child: const Text('Gửi báo cáo mẫu'),
      ),
    ],
  );
}
