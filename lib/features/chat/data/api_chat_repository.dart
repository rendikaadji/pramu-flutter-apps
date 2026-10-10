import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/features/chat/domain/chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Conversation>> conversations() async => [
    for (final c in await _api.get('/conversations') as List)
      Conversation.fromJson(c as Json),
  ];

  @override
  Future<List<ChatMessage>> messages(
    String conversationId, {
    String? afterId,
  }) async => [
    for (final m in await _api.get(
      '/conversations/$conversationId/messages',
      query: {'after': ?afterId},
    ) as List)
      ChatMessage.fromJson(m as Json),
  ];

  @override
  Future<ChatMessage> send(String conversationId, String text) async =>
      ChatMessage.fromJson(
        await _api.post(
          '/conversations/$conversationId/messages',
          data: {'text': text},
        ) as Json,
      );

  @override
  Future<void> markRead(String conversationId) =>
      _api.post('/conversations/$conversationId/read');

  /// ponytail: polling 5 dtk. Ganti ke Reverb setelah spike klien realtime (docs/01 §6.5).
  @override
  Stream<ChatMessage> incoming(String conversationId) async* {
    String? last;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final fresh = await messages(conversationId, afterId: last);
      for (final m in fresh) {
        yield m;
      }
      if (fresh.isNotEmpty) last = fresh.last.id;
    }
  }
}
