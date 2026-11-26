import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import 'chat_avatar.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.isLoading,
    required this.canClear,
    required this.onNewConversation,
    required this.onOpenHistory,
    required this.onClear,
  });

  final bool isLoading;
  final bool canClear;
  final VoidCallback onNewConversation;
  final VoidCallback onOpenHistory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: AppColors.chatPrimary,
      backgroundColor: AppColors.chatBackground,
      minimumSize: const Size.square(44),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.chatBorder),
          ),
        ),
        child: SafeArea(
          left: false,
          right: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  style: buttonStyle,
                ),
                const UthAiAvatar(size: 36),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'UTH AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        isLoading ? 'Đang soạn câu trả lời…' : 'Trợ lý UTH Lab',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                MenuAnchor(
                  alignmentOffset: const Offset(-12, 6),
                  style: MenuStyle(
                    alignment: AlignmentDirectional.bottomEnd,
                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                    surfaceTintColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.chatBorder),
                      ),
                    ),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: canClear ? onNewConversation : null,
                      leadingIcon: const Icon(Icons.add_comment_outlined),
                      child: const Text('Cuộc trò chuyện mới'),
                    ),
                    MenuItemButton(
                      onPressed: onOpenHistory,
                      leadingIcon: const Icon(Icons.history_rounded),
                      child: const Text('Lịch sử trò chuyện'),
                    ),
                    MenuItemButton(
                      onPressed: canClear ? onClear : null,
                      leadingIcon: const Icon(Icons.delete_outline_rounded),
                      child: const Text('Xóa hội thoại'),
                    ),
                  ],
                  builder: (context, controller, child) => IconButton(
                    tooltip: 'Tùy chọn hội thoại',
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    style: buttonStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
