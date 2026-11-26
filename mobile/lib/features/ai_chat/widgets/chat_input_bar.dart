import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../controllers/chat_voice_input.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.input,
    required this.image,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onSend,
  });

  final TextEditingController input;
  final Uint8List? image;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final ValueChanged<String> onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final _voice = ChatVoiceInput(
    onText: (text) {
      widget.input.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    },
    onError: (message) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    },
  );

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.chatBorder)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.image case final photo?)
              InputChip(
                label: const Text('Ảnh đính kèm'),
                avatar: Image.memory(photo, width: 24, fit: BoxFit.cover),
                onDeleted: widget.onRemovePhoto,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Hỏi UTH AI…',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.feedbackBackground,
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        11,
                        0,
                        11,
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: BorderSide(color: colors.primary),
                      ),
                      prefixIcon: IconButton(
                        tooltip: 'Thêm ảnh',
                        onPressed: widget.onPickPhoto,
                        icon: const Icon(Icons.add_rounded, size: 19),
                        color: AppColors.chatPrimary,
                      ),
                      suffixIcon: ListenableBuilder(
                        listenable: _voice,
                        builder: (context, _) => IconButton(
                          tooltip: _voice.listening
                              ? 'Dừng nhập giọng nói'
                              : 'Nhập bằng giọng nói',
                          color: AppColors.chatPrimary,
                          onPressed: _voice.starting
                              ? null
                              : () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  _voice.toggle(widget.input.text);
                                },
                          icon: Icon(
                            _voice.listening
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder(
                  valueListenable: widget.input,
                  builder: (context, value, _) => IconButton.filled(
                    tooltip: 'Gửi câu hỏi',
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(44),
                      shape: const CircleBorder(),
                      backgroundColor: AppColors.chatPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.chatPrimary,
                      disabledForegroundColor: Colors.white,
                    ),
                    onPressed: value.text.trim().isEmpty && widget.image == null
                        ? null
                        : () {
                            _voice.cancel();
                            widget.onSend(value.text);
                          },
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'UTH AI có thể sai. Hãy kiểm tra thông tin quan trọng.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
