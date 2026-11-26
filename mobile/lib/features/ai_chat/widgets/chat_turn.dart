import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import 'chat_avatar.dart';
import 'chat_bubble.dart';
import 'chat_reply_cards.dart';
import 'chat_welcome.dart';

class ChatTurn extends StatelessWidget {
  const ChatTurn({
    super.key,
    required this.message,
    required this.latest,
    required this.isTechnician,
    required this.controller,
    required this.onSend,
    required this.onOpenSchedule,
    required this.onOpenReports,
    required this.onEditIncident,
  });

  final ChatMessage message;
  final bool latest;
  final bool isTechnician;
  final ChatController controller;
  final void Function(String, {ChatRoom? room}) onSend;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenReports;
  final ValueChanged<ChatMessage> onEditIncident;

  @override
  Widget build(BuildContext context) {
    final reply = message.reply;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          ChatBubble(
            user: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                if (message.text.isNotEmpty) Text(message.text),
                if (message.image case final photo?)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(photo, height: 100, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          if (reply == null)
            const ChatTypingIndicator()
          else ...[
            if (reply.type == ChatReplyType.rooms)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  const UthAiAvatar(size: 26),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        const Chip(
                          avatar: Icon(
                            Icons.event_available_outlined,
                            size: 16,
                          ),
                          label: Text('Lịch phòng mẫu'),
                          backgroundColor: AppColors.chatTint,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(reply.text),
                      ],
                    ),
                  ),
                ],
              )
            else
              ChatBubble(child: Text(reply.text)),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32),
              child: ChatReplyCards(
                message: message,
                controller: controller,
                onSend: onSend,
                onOpenSchedule: onOpenSchedule,
                onOpenReports: onOpenReports,
                onEditIncident: () => onEditIncident(message),
              ),
            ),
            if (reply.type == ChatReplyType.unknown)
              Wrap(
                spacing: 6,
                children: [
                  for (final (_, question) in chatSuggestions(
                    isTechnician: isTechnician,
                  ).take(3))
                    ActionChip(
                      label: Text(question),
                      onPressed: () => onSend(question),
                    ),
                ],
              ),
            if (latest && reply.type != ChatReplyType.error)
              _copyButton(reply.text),
          ],
        ],
      ),
    );
  }

  Widget _copyButton(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 26),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        tooltip: 'Sao chép câu trả lời',
        iconSize: 16,
        icon: const Icon(Icons.copy_outlined),
        onPressed: () => Clipboard.setData(ClipboardData(text: text)),
      ),
    ),
  );
}
