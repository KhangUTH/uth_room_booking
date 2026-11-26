import '../../booking/models/booking.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  const MockChatRepository({required this.loadSchedule});

  final Future<List<Booking>> Function(ScheduleQuestion) loadSchedule;

  static const rooms = <ChatRoom>[
    (
      name: 'Phòng A2.03',
      shift: 'Ca chiều',
      time: '13:00 – 16:30',
      capacity: 40,
      available: 24,
    ),
    (
      name: 'Phòng B1.07',
      shift: 'Ca chiều',
      time: '13:00 – 16:30',
      capacity: 40,
      available: 18,
    ),
  ];

  @override
  Future<ChatReply> replyTo(ChatMessage message) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final text = message.text.toLowerCase();
    if (text.contains('so sánh 2 phòng')) {
      return ChatReply(
        ChatReplyType.text,
        '${rooms.first.name} còn ${rooms.first.available} máy, '
        'còn ${rooms.last.name} có ${rooms.last.available} máy trong cùng ca mẫu.',
      );
    }
    var selectedRoom = message.room;
    if (selectedRoom == null && text.contains('đặt phòng')) {
      selectedRoom = rooms
          .where(
            (room) => text.contains(
              room.name.toLowerCase().replaceFirst('phòng ', ''),
            ),
          )
          .firstOrNull;
    }
    if (selectedRoom != null) {
      return ChatReply(
        ChatReplyType.booking,
        'Bạn kiểm tra lại ca mẫu trước khi xác nhận nhé.',
        room: selectedRoom,
        rooms: rooms,
      );
    }
    if (text.contains('trạng thái') ||
        text.contains('sao rồi') ||
        text.contains('lỗ cắm')) {
      return const ChatReply(
        ChatReplyType.report,
        'Đây là trạng thái báo cáo mẫu.',
      );
    }
    if (message.image != null ||
        text.contains('sự cố') ||
        text.contains('hư')) {
      return const ChatReply(
        ChatReplyType.incident,
        'Bạn kiểm tra mô tả và chọn phòng hoặc thiết bị trong form báo cáo.',
      );
    }
    if (text.contains('phòng trống') ||
        text.contains('phòng nào') ||
        text.contains('còn trống') ||
        text.contains('đặt phòng')) {
      return const ChatReply(
        ChatReplyType.rooms,
        'Chiều nay có 2 phòng trống trong danh sách mẫu. Phòng A2.03 còn nhiều máy nhất.',
        rooms: rooms,
      );
    }
    final question =
        ScheduleQuestion.fromMessage(text) ??
        (text.contains('lịch của tôi') ? ScheduleQuestion.next : null);
    if (question != null) {
      final bookings = await loadSchedule(question);
      return ChatReply(
        ChatReplyType.schedule,
        bookings.isEmpty
            ? 'Bạn chưa có lịch đăng ký phù hợp.'
            : 'Mình tìm thấy các đăng ký sau.',
        bookings: bookings,
      );
    }
    if (text.contains('thiết bị')) {
      return const ChatReply(
        ChatReplyType.text,
        'Vào Lịch → Thiết bị để chọn ngày, ca và thiết bị cần sử dụng.',
      );
    }
    return const ChatReply(
      ChatReplyType.unknown,
      'Mình chưa hiểu ý bạn. Hãy thử một câu gợi ý.',
    );
  }
}
