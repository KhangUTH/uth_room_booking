import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/app_notice.dart';

const _muted = Color(0xFF596577);
const _border = Color(0xFFDFE5EA);

class NoticeDetailsSheet extends StatelessWidget {
  const NoticeDetailsSheet({
    super.key,
    required this.notice,
    this.relatedDetails,
  });

  final AppNotice notice;
  final Widget? relatedDetails;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              backgroundColor: const Color(0xFFE3F2F3),
              foregroundColor: AppColors.primary,
              child: Icon(notice.icon),
            ),
          ),
          const SizedBox(height: 12),
          Text(notice.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(notice.metadata, style: const TextStyle(color: _muted)),
          const SizedBox(height: 12),
          SelectableText(notice.message),
          if (relatedDetails case final details?) ...[
            const SizedBox(height: 16),
            details,
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.notice,
    required this.isRead,
    required this.saved,
    required this.selecting,
    required this.selected,
    this.opening = false,
    this.onTap,
    this.onLongPress,
    this.onSave,
  });

  final AppNotice notice;
  final bool isRead;
  final bool saved;
  final bool selecting;
  final bool selected;
  final bool opening;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? const Color(0xFFE3F2F3)
        : isRead
        ? Colors.white
        : const Color(0xFFF0F8F8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: _border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE3F2F3),
              foregroundColor: AppColors.primary,
              child: opening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                        semanticsLabel: 'Đang mở chi tiết báo cáo',
                      ),
                    )
                  : Icon(notice.icon, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF172033),
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice.message,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice.metadata,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selecting)
              Checkbox(
                value: selected,
                semanticLabel: 'Chọn ${notice.title}',
                onChanged: onTap == null ? null : (_) => onTap!(),
              )
            else
              IconButton(
                tooltip: saved ? 'Bỏ lưu thông báo' : 'Lưu thông báo',
                onPressed: onSave,
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
