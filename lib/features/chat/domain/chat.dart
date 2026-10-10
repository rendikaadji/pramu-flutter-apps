import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

enum SendStatus {
  sending,
  sent,
  failed;

  static SendStatus from(String? s) => enumFromWire(values, s, sent);

  String get label => switch (this) {
    sending => 'Mengirim',
    sent => 'Terkirim',
    failed => 'Gagal, ketuk untuk ulangi',
  };
}

class Conversation {
  const Conversation({
    required this.id,
    required this.counterpart,
    this.applicationId,
    this.bookingId,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'] as String,
    counterpart: UserCard.fromJson(j['counterpart'] as Map<String, dynamic>),
    applicationId: j['application_id'] as String?,
    bookingId: j['booking_id'] as String?,
    lastMessage: j['last_message'] as String?,
    lastAt: j['last_at'] == null ? null : parseApiTime(j['last_at'] as String),
    unread: j['unread'] as int? ?? 0,
  );

  final String id;
  final UserCard counterpart;
  final String? applicationId;
  final String? bookingId;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.readAt,
    this.masked = false,
    this.status = SendStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    conversationId: j['conversation_id'] as String,
    senderId: j['sender_id'] as String,
    text: j['text'] as String,
    createdAt: parseApiTime(j['created_at'] as String),
    readAt: j['read_at'] == null ? null : parseApiTime(j['read_at'] as String),
    masked: j['masked'] as bool? ?? false,
  );

  final String id;
  final String conversationId;
  final String senderId;

  /// Sudah disamarkan server; tampilkan apa adanya, render sebagai teks polos.
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool masked;
  final SendStatus status;
}
