import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class ChatHistorySheet extends StatelessWidget {
  const ChatHistorySheet({super.key, required this.titles, this.currentTitle});

  final List<String> titles;
  final String? currentTitle;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          'Lịch sử trò chuyện',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (currentTitle case final title?)
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: const Text('Đang mở'),
            iconColor: AppColors.chatPrimary,
          ),
        for (final (index, title) in titles.indexed)
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            iconColor: AppColors.chatPrimary,
            onTap: () => Navigator.pop(context, index),
          ),
        if (titles.isEmpty && currentTitle == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Bạn chưa có cuộc trò chuyện nào.'),
          ),
      ],
    ),
  );
}
