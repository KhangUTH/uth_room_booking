import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/chat_message.dart';

class ChatRoomCard extends StatelessWidget {
  const ChatRoomCard({
    super.key,
    required this.room,
    required this.featured,
    required this.onBook,
  });

  final ChatRoom room;
  final bool featured;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final fraction = room.capacity > 0
        ? (room.available / room.capacity).clamp(0.0, 1.0)
        : 0.0;
    final label = '${room.available}/${room.capacity} máy trống';
    final textTheme = Theme.of(context).textTheme;
    const badgeColor = AppColors.chatTint;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.chatBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 9,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.desktop_windows_outlined,
                    size: 19,
                    color: AppColors.chatPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: textTheme.titleSmall),
                    Text(
                      '${room.shift} · ${room.time}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text('${(fraction * 100).round()}%'),
                labelStyle: const TextStyle(color: AppColors.chatPrimary),
                backgroundColor: badgeColor,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          LinearProgressIndicator(
            value: fraction.toDouble(),
            color: AppColors.chatPrimary,
            backgroundColor: badgeColor,
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
            semanticsLabel: label,
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              if (featured)
                FilledButton(onPressed: onBook, child: const Text('Đặt ngay'))
              else
                OutlinedButton(
                  onPressed: onBook,
                  child: const Text('Đặt ngay'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
