import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/chat/data/chat_providers.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

/// M-60.
class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    return ref.read(chatRepositoryProvider).conversations();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).conversations(),
    );
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
      ConversationsNotifier.new,
      retry: noRetry,
    );

class ChatRoomState {
  const ChatRoomState({this.messages = const [], this.reconnecting = false});

  /// lama -> baru; id `local_*` = belum diterima server.
  final List<ChatMessage> messages;
  final bool reconnecting;
}

ChatMessage _withStatus(ChatMessage m, SendStatus s) => ChatMessage(
  id: m.id,
  conversationId: m.conversationId,
  senderId: m.senderId,
  text: m.text,
  createdAt: m.createdAt,
  readAt: m.readAt,
  masked: m.masked,
  status: s,
);

/// M-61. REST = sumber kebenaran; `incoming` (polling 5 dtk di repository) hanya menambah pesan.
class ChatRoomNotifier extends AsyncNotifier<ChatRoomState> {
  ChatRoomNotifier(this.conversationId);
  final String conversationId;

  int _seq = 0;
  StreamSubscription<ChatMessage>? _sub;
  Timer? _retry;

  String get _me => ref.read(sessionProvider).user?.id ?? '';

  @override
  Future<ChatRoomState> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    ref.onDispose(() {
      _sub?.cancel();
      _retry?.cancel();
    });
    final repo = ref.read(chatRepositoryProvider);
    final list = await repo.messages(conversationId);
    // Ruang ditutup selama menunggu: jangan buka langganan polling yang tak pernah dibatalkan.
    if (!ref.mounted) return ChatRoomState(messages: list);
    _listen(afterId: list.isEmpty ? null : list.last.id);
    unawaited(_markRead());
    return ChatRoomState(messages: list);
  }

  Future<void> _markRead() async {
    try {
      await ref.read(chatRepositoryProvider).markRead(conversationId);
    } on Exception {
      // tidak kritis; dicoba lagi pada pesan masuk berikutnya
    }
  }

  void _listen({String? afterId}) {
    _sub?.cancel();
    final loaded = state.value?.messages.where(
      (m) => !m.id.startsWith('local_'),
    );
    _sub = ref
        .read(chatRepositoryProvider)
        .incoming(
          conversationId,
          afterId:
              afterId ?? (loaded?.isEmpty ?? true ? null : loaded!.last.id),
        )
        .listen(
          _onIncoming,
          onError: (Object _) {
            _set(reconnecting: true);
            _retry?.cancel();
            _retry = Timer(const Duration(seconds: 5), () {
              if (ref.mounted) _listen();
            });
          },
        );
  }

  void _set({List<ChatMessage>? messages, bool? reconnecting}) {
    final cur = state.value;
    if (cur == null || !ref.mounted) return;
    state = AsyncData(
      ChatRoomState(
        messages: messages ?? cur.messages,
        reconnecting: reconnecting ?? cur.reconnecting,
      ),
    );
  }

  void _onIncoming(ChatMessage m) {
    final cur = state.value;
    if (cur == null || cur.messages.any((e) => e.id == m.id)) return;
    _set(messages: [...cur.messages, m], reconnecting: false);
    if (m.senderId != _me) unawaited(_markRead());
  }

  /// Optimistik: tampil `sending`, diganti pesan server (sudah disamarkan) bila sukses.
  Future<void> send(String text) async {
    final t = text.trim();
    final cur = state.value;
    if (t.isEmpty || cur == null) return;
    final local = ChatMessage(
      id: 'local_${_seq++}',
      conversationId: conversationId,
      senderId: _me,
      text: t,
      createdAt: DateTime.now().toUtc(),
      status: SendStatus.sending,
    );
    _set(messages: [...cur.messages, local]);
    await _deliver(local);
  }

  Future<void> retry(String localId) async {
    final m = state.value?.messages.where((e) => e.id == localId).firstOrNull;
    if (m == null || m.status != SendStatus.failed) return;
    _replace(localId, _withStatus(m, SendStatus.sending));
    await _deliver(m);
  }

  Future<void> _deliver(ChatMessage local) async {
    try {
      final sent = await ref
          .read(chatRepositoryProvider)
          .send(conversationId, local.text);
      final list = state.value?.messages ?? const <ChatMessage>[];
      if (list.any((e) => e.id == sent.id)) {
        _set(
          messages: [
            for (final e in list)
              if (e.id != local.id) e,
          ],
        );
      } else {
        _replace(local.id, sent);
      }
    } on Exception {
      _replace(local.id, _withStatus(local, SendStatus.failed));
    }
  }

  void _replace(String id, ChatMessage next) {
    final list = state.value?.messages;
    if (list == null) return;
    _set(messages: [for (final e in list) e.id == id ? next : e]);
  }
}

final chatRoomProvider = AsyncNotifierProvider.autoDispose
    .family<ChatRoomNotifier, ChatRoomState, String>(
      ChatRoomNotifier.new,
      retry: noRetry,
    );

/// Kontak pribadi terbuka bila ada period yang sudah dibayar (banner hijau).
final contactsOpenProvider = FutureProvider.autoDispose.family<bool, String?>((
  ref,
  bookingId,
) async {
  if (bookingId == null) return false;
  try {
    final b = await ref.read(bookingRepositoryProvider).booking(bookingId);
    return b.periods.any(
      (p) =>
          p.status.canDispute ||
          p.status == PeriodStatus.completed ||
          p.status == PeriodStatus.settled,
    );
  } on Exception {
    return false;
  }
}, retry: noRetry);
