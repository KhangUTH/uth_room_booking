import '../../technician/models/task_filter.dart';
import '../../technician/models/technician_task.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

class TechnicianChatRepository implements ChatRepository {
  const TechnicianChatRepository({required this.loadJobs});

  final Future<List<TechnicianTask>> Function() loadJobs;

  @override
  Future<ChatReply> replyTo(ChatMessage message) async {
    if (message.image != null) {
      return const ChatReply(
        ChatReplyType.text,
        'Bạn có thể mở mục Công việc để xem ảnh và chi tiết sự cố.',
      );
    }
    final question = message.text.toLowerCase();
    final filter = switch (question) {
      _ when question.contains('gấp') || question.contains('khẩn') =>
        TaskFilter.urgent,
      _ when question.contains('chờ nhận') || question.contains('chưa nhận') =>
        TaskFilter.pending,
      _ when question.contains('đang xử lý') || question.contains('đang sửa') =>
        TaskFilter.active,
      _ when question.contains('hoàn tất') || question.contains('hoàn thành') =>
        TaskFilter.completed,
      _ => null,
    };
    if (filter == null) {
      return const ChatReply(
        ChatReplyType.unknown,
        'Bạn có thể hỏi về việc chờ nhận, đang xử lý, đã hoàn tất hoặc việc gấp.',
      );
    }

    final jobs = (await loadJobs()).where(filter.matches).toList();
    if (jobs.isEmpty) {
      return ChatReply(
        ChatReplyType.text,
        'Hiện chưa có công việc thuộc nhóm ${filter.label.toLowerCase()}.',
      );
    }
    return ChatReply(
      ChatReplyType.text,
      [
        'Có ${jobs.length} công việc thuộc nhóm ${filter.label.toLowerCase()}.',
        for (final job in jobs.take(5))
          '• ${job.title}${job.location.isEmpty ? '' : ' · ${job.location}'}',
        if (jobs.length > 5) 'Mở tab Công việc để xem danh sách đầy đủ.',
      ].join('\n'),
    );
  }
}
