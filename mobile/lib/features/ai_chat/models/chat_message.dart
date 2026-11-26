import 'dart:typed_data';

import '../../booking/models/booking.dart';

typedef ChatRoom = ({
  String name,
  String shift,
  String time,
  int capacity,
  int available,
});

enum ChatReplyType {
  schedule,
  rooms,
  booking,
  report,
  incident,
  unknown,
  error,
  text,
}

class ChatReply {
  const ChatReply(
    this.type,
    this.text, {
    this.rooms = const [],
    this.bookings = const [],
    this.room,
  });

  final ChatReplyType type;
  final String text;
  final List<ChatRoom> rooms;
  final List<Booking> bookings;
  final ChatRoom? room;
}

class ChatMessage {
  ChatMessage(this.text, {this.image, this.room});

  final String text;
  final Uint8List? image;
  final ChatRoom? room;
  ChatReply? reply;
  bool confirmed = false;
}
