import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../booking/widgets/booking_history_card.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import 'chat_room_card.dart';

class ChatReplyCards extends StatelessWidget {
  const ChatReplyCards({
    super.key,
    required this.message,
    required this.controller,
    required this.onSend,
    required this.onOpenSchedule,
    required this.onOpenReports,
    required this.onEditIncident,
  });

  final ChatMessage message;
  final ChatController controller;
  final void Function(String, {ChatRoom? room}) onSend;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenReports;
  final VoidCallback onEditIncident;

  @override
  Widget build(BuildContext context) {
    final reply = message.reply!;
    final colors = Theme.of(context).colorScheme;
    return switch (reply.type) {
      ChatReplyType.rooms => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          for (final (index, room) in reply.rooms.indexed)
            ChatRoomCard(
              room: room,
              featured: index == 0,
              onBook: () => _bookRoom(room),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (reply.rooms.firstOrNull case final room?)
                ActionChip(
                  label: Text('Đặt ${room.name.replaceFirst('Phòng ', '')}'),
                  onPressed: () => _bookRoom(room),
                ),
              ActionChip(
                label: const Text('Xem lịch ngày mai'),
                onPressed: () => onSend('Ngày mai mình có lịch gì?'),
              ),
              if (reply.rooms.length == 2)
                ActionChip(
                  label: const Text('So sánh 2 phòng'),
                  onPressed: () => onSend('So sánh 2 phòng'),
                ),
            ],
          ),
        ],
      ),
      ChatReplyType.booking => _card(
        context,
        color: AppColors.feedbackBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message.confirmed ? 'Đã đặt mẫu' : 'Xác nhận đặt phòng',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text('Phòng · ${reply.room!.name}'),
            Text('Thời gian · ${reply.room!.shift}, hôm nay'),
            if (message.confirmed)
              TextButton(
                onPressed: onOpenSchedule,
                child: const Text('Xem lịch'),
              )
            else
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => controller.confirm(message),
                      child: const Text('Xác nhận'),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _editRoom(context, reply.rooms),
                      child: const Text('Sửa'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      ChatReplyType.report => _card(
        context,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.assignment_turned_in_outlined,
            color: colors.primary,
          ),
          title: const Text('Hư lỗ cắm'),
          subtitle: const Text('Kỹ thuật viên đã hoàn tất công việc'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenReports,
        ),
      ),
      ChatReplyType.incident => _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Text(
              message.confirmed
                  ? 'Đã gửi báo cáo mẫu'
                  : 'Bản nháp báo cáo sự cố',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (!message.confirmed && message.text.isNotEmpty)
              Text(message.text),
            if (!message.confirmed)
              FilledButton(
                onPressed: onEditIncident,
                child: const Text('Kiểm tra báo cáo'),
              ),
            TextButton(
              onPressed: onOpenReports,
              child: const Text('Mở trang Báo cáo'),
            ),
          ],
        ),
      ),
      ChatReplyType.schedule => Column(
        spacing: 8,
        children: [
          for (final booking in reply.bookings)
            BookingHistoryCard(booking: booking),
        ],
      ),
      ChatReplyType.error => Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () => controller.retry(message),
          child: const Text('Thử lại'),
        ),
      ),
      ChatReplyType.unknown || ChatReplyType.text => const SizedBox.shrink(),
    };
  }

  void _bookRoom(ChatRoom room) => onSend(
    'Đặt phòng ${room.name.replaceFirst('Phòng ', '')} ${room.shift}',
    room: room,
  );

  Future<void> _editRoom(BuildContext context, List<ChatRoom> rooms) async {
    final selected = await showModalBottomSheet<ChatRoom>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final room in rooms)
              ListTile(
                title: Text(room.name),
                subtitle: Text('${room.shift} · ${room.time}'),
                onTap: () => Navigator.pop(context, room),
              ),
          ],
        ),
      ),
    );
    if (context.mounted && selected != null) {
      controller.changeRoom(message, selected);
    }
  }

  Widget _card(BuildContext context, {required Widget child, Color? color}) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: color ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}
