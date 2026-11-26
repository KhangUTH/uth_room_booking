import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chat_repository.dart';
import '../models/chat_message.dart';

class ChatController extends ChangeNotifier {
  ChatController(this._repository);

  final ChatRepository _repository;
  var _messages = <ChatMessage>[];
  final _history = <List<ChatMessage>>[];
  bool _disposed = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Object get conversationKey => _messages;
  bool get isLoading => _messages.any((message) => message.reply == null);
  String? get currentTitle => _messages.isEmpty ? null : _titleOf(_messages);
  List<String> get historyTitles => [
    for (final conversation in _history) _titleOf(conversation),
  ];

  String _titleOf(List<ChatMessage> conversation) =>
      conversation.first.text.isEmpty
      ? 'Cuộc trò chuyện có ảnh'
      : conversation.first.text;

  void startNewConversation() {
    if (_messages.isEmpty) return;
    _history.insert(0, _messages);
    _messages = [];
    notifyListeners();
  }

  void openConversation(int index) {
    final selected = _history.removeAt(index);
    if (_messages.isNotEmpty) _history.insert(0, _messages);
    _messages = selected;
    notifyListeners();
  }

  void send(String text, {Uint8List? image, ChatRoom? room}) {
    final message = text.trim();
    if (message.isEmpty && image == null) return;
    final entry = ChatMessage(message, image: image, room: room);
    _messages.add(entry);
    unawaited(_load(entry));
  }

  void retry(ChatMessage message) {
    if (message.reply?.type == ChatReplyType.error) unawaited(_load(message));
  }

  Future<void> _load(ChatMessage message) async {
    message.reply = null;
    notifyListeners();
    ChatReply reply;
    try {
      reply = await _repository.replyTo(message);
    } catch (_) {
      reply = const ChatReply(
        ChatReplyType.error,
        'Không kết nối được. Kiểm tra mạng rồi thử lại.',
      );
    }
    if (_disposed ||
        (!_messages.contains(message) &&
            !_history.any((conversation) => conversation.contains(message)))) {
      return;
    }
    message.reply = reply;
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }

  void confirm(ChatMessage message) {
    message.confirmed = true;
    notifyListeners();
  }

  void changeRoom(ChatMessage message, ChatRoom room) {
    final reply = message.reply;
    if (reply?.type != ChatReplyType.booking || message.confirmed) return;
    message.reply = ChatReply(
      ChatReplyType.booking,
      reply!.text,
      room: room,
      rooms: reply.rooms,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
