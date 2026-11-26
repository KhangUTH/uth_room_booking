import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'chat_avatar.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.child, this.user = false});

  final Widget child;
  final bool user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: user
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: user ? .8 : .9,
        alignment: user
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: user
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          spacing: 6,
          children: [
            if (!user) const UthAiAvatar(size: 26),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: user ? AppColors.chatPrimary : Colors.white,
                  border: user
                      ? null
                      : Border.all(
                          color: AppColors.chatPrimary.withValues(alpha: .24),
                        ),
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(16),
                    topEnd: const Radius.circular(16),
                    bottomStart: Radius.circular(user ? 16 : 4),
                    bottomEnd: Radius.circular(user ? 4 : 16),
                  ),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 14,
                    color: user ? colors.onPrimary : colors.onSurface,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang soạn câu trả lời',
    child: ChatBubble(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(0, (_animation.value * 3).floor() == i ? -3 : 0),
                child: CircleAvatar(
                  radius: 3,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
