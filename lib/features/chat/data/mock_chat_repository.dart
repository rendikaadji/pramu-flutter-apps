import 'dart:async';

import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/features/chat/domain/chat_repository.dart';

/// Kirim teks `/gagal` -> 503 (uji status "gagal + ulangi"). Kontak disamarkan sampai ada period dibayar.
/// Bila ada pendengar `incoming`, lawan bicara membalas otomatis 1,5 dtk setelah kirim.
class MockChatRepository implements ChatRepository {
  MockChatRepository(this._b);
  final MockBackend _b;
  final _streams = <String, StreamController<ChatMessage>>{};

  MockConversation _conv(String id) {
    final c = _b.conversations[id];
    final uid = _b.me.id;
    if (c == null || (c.seekerId != uid && c.assistantId != uid)) {
      apiFail(404, 'NOT_FOUND', 'Percakapan tidak ditemukan.');
    }
    return c;
  }

  bool _unmasked(MockConversation c) {
    final bid = c.bookingId;
    if (bid == null) return false;
    return _b.bookingPeriods[bid]!.any((p) {
      final s = _b.periods[p]!.status;
      return s == PeriodStatus.paid ||
          s == PeriodStatus.inProgress ||
          s == PeriodStatus.awaitingConfirmation ||
          s.isFinal && s != PeriodStatus.cancelled;
    });
  }

  @override
  Future<List<Conversation>> conversations() => _b.run(() {
    final uid = _b.me.id;
    final list = <Conversation>[];
    for (final c in _b.conversations.values) {
      if (c.seekerId != uid && c.assistantId != uid) continue;
      final msgs = _b.messages[c.id] ?? const [];
      list.add(
        Conversation(
          id: c.id,
          counterpart: _b.card(c.seekerId == uid ? c.assistantId : c.seekerId),
          applicationId: c.applicationId,
          bookingId: c.bookingId,
          lastMessage: msgs.isEmpty ? null : msgs.last.text,
          lastAt: msgs.isEmpty ? null : msgs.last.createdAt,
          unread: msgs
              .where((m) => m.senderId != uid && m.readAt == null)
              .length,
        ),
      );
    }
    return list..sort(
      (a, b) => (b.lastAt ?? DateTime(0)).compareTo(a.lastAt ?? DateTime(0)),
    );
  });

  @override
  Future<List<ChatMessage>> messages(
    String conversationId, {
    String? afterId,
  }) => _b.run(() {
    _conv(conversationId);
    final all = _b.messages[conversationId] ?? const <ChatMessage>[];
    final i = afterId == null ? -1 : all.indexWhere((m) => m.id == afterId);
    return all.sublist(i + 1);
  });

  @override
  Future<ChatMessage> send(String conversationId, String text) => _b.run(() {
    final c = _conv(conversationId);
    final me = _b.me;
    final t = text.trim();
    if (t.isEmpty || t.length > 2000) {
      apiFail(422, 'VALIDATION_FAILED', 'Pesan harus 1 sampai 2000 karakter.', {
        'text': ['Pesan tidak valid'],
      });
    }
    if (t == '/gagal') {
      apiFail(503, 'SERVICE_UNAVAILABLE', 'Server sedang sibuk. Coba lagi.');
    }
    final shown = _unmasked(c) ? t : MockBackend.maskContacts(t);
    final m = ChatMessage(
      id: _b.newId(),
      conversationId: conversationId,
      senderId: me.id,
      text: shown,
      createdAt: _b.now(),
      masked: shown != t,
    );
    (_b.messages[conversationId] ??= []).add(m);
    final stream = _streams[conversationId];
    if (stream != null && stream.hasListener) {
      Timer(const Duration(milliseconds: 1500), () {
        if (stream.isClosed) return;
        final other = c.seekerId == me.id ? c.assistantId : c.seekerId;
        final reply = ChatMessage(
          id: _b.newId(),
          conversationId: conversationId,
          senderId: other,
          text: 'Baik, terima kasih. Saya cek dulu ya.',
          createdAt: _b.now(),
        );
        _b.messages[conversationId]!.add(reply);
        stream.add(reply);
      });
    }
    return m;
  });

  @override
  Future<void> markRead(String conversationId) => _b.run(() {
    _conv(conversationId);
    final uid = _b.me.id;
    final list = _b.messages[conversationId] ?? [];
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (m.senderId != uid && m.readAt == null) {
        list[i] = ChatMessage(
          id: m.id,
          conversationId: m.conversationId,
          senderId: m.senderId,
          text: m.text,
          createdAt: m.createdAt,
          readAt: _b.now(),
          masked: m.masked,
        );
      }
    }
  });

  @override
  Stream<ChatMessage> incoming(String conversationId) =>
      (_streams[conversationId] ??= StreamController<ChatMessage>.broadcast())
          .stream;
}
