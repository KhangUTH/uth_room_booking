import '../models/chat_message.dart';

abstract interface class ChatRepository {
  Future<ChatReply> replyTo(ChatMessage message);
}
