import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'chat_avatar.dart';

List<(IconData, String)> chatSuggestions({required bool isTechnician}) =>
    isTechnician
    ? const [
        (Icons.assignment_outlined, 'Có sự cố nào đang chờ nhận?'),
        (Icons.build_outlined, 'Mình đang xử lý những việc nào?'),
        (Icons.warning_amber_rounded, 'Có sự cố gấp nào không?'),
        (Icons.task_alt_outlined, 'Mình đã hoàn tất những việc nào?'),
      ]
    : const [
        (Icons.desktop_windows_outlined, 'Chiều nay phòng máy nào còn trống?'),
        (Icons.smartphone_outlined, 'Đăng ký sử dụng thiết bị thế nào?'),
        (Icons.schedule_outlined, 'Ca đăng ký tiếp theo là khi nào?'),
        (Icons.assignment_outlined, 'Mình báo cáo sự cố ở đâu?'),
      ];

class ChatWelcome extends StatelessWidget {
  const ChatWelcome({
    super.key,
    required this.name,
    required this.onSend,
    required this.isTechnician,
  });
  final String name;
  final ValueChanged<String> onSend;
  final bool isTechnician;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final givenName = name.trim().split(RegExp(r'\s+')).last;
    final suggestions = chatSuggestions(isTechnician: isTechnician);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        const Center(child: ChatHero()),
        const SizedBox(height: 10),
        Text(
          givenName.isEmpty ? 'Xin chào!' : 'Xin chào, $givenName',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTechnician
              ? 'Mình là UTH AI. Hỏi mình về sự cố và công việc kỹ thuật.'
              : 'Mình là UTH AI. Hỏi mình về phòng máy, thiết bị và báo cáo sự cố.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Gợi ý nhanh',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 280 ? 1 : 2;
            return Column(
              spacing: 8,
              children: [
                for (
                  var start = 0;
                  start < suggestions.length;
                  start += columns
                )
                  IntrinsicHeight(
                    child: Row(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = start;
                          index < start + columns;
                          index++
                        )
                          Expanded(
                            child: _SuggestionCard(
                              question: suggestions[index].$2,
                              icon: suggestions[index].$1,
                              highlighted: index == 0,
                              onTap: () => onSend(suggestions[index].$2),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.question,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  final String question;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: highlighted ? AppColors.feedbackBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: highlighted ? AppColors.chatTint : AppColors.chatBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 9,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: highlighted
                          ? AppColors.chatTint
                          : AppColors.chatBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 17, color: AppColors.chatPrimary),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: highlighted
                        ? AppColors.chatPrimary
                        : colors.onSurfaceVariant,
                  ),
                ],
              ),
              Text(
                question,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
