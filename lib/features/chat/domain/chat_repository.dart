import 'package:pramu_apps/features/chat/domain/chat.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> conversations();

  /// Urut naik (lama -> baru). [afterId] = sinkron setelah reconnect.
  Future<List<ChatMessage>> messages(String conversationId, {String? afterId});

  /// REST adalah sumber kebenaran. Hasilnya sudah disamarkan server.
  Future<ChatMessage> send(String conversationId, String text);

  Future<void> markRead(String conversationId);

  /// Pesan masuk realtime. Impl API: polling REST (Reverb = spike terpisah).
  /// [afterId] = pesan terakhir yang sudah dimuat; polling hanya mengambil yang lebih baru.
  Stream<ChatMessage> incoming(String conversationId, {String? afterId});
}
