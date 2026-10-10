import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/features/chat/presentation/state/chat_state.dart';
import 'package:pramu_apps/features/chat/presentation/widgets/message_bubble.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/report_path.dart';

/// Heuristik tampilan saja: pola nomor/email/tautan. Penyamaran asli di server.
final _contactLike = RegExp(
  r'(\d[\s-]*){9,}|@|https?://|www\.',
  caseSensitive: false,
);

const _privacyText =
    'Jaga transaksi tetap di aplikasi agar dana dan data Anda terlindungi. '
    'Nomor disembunyikan sampai pembayaran dilakukan, demi keamanan Anda.';

enum _Menu { report, share }

/// M-61 Ruang chat.
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _input = TextEditingController();
  bool _bannerClosed = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Conversation? get _conversation => ref
      .watch(conversationsProvider)
      .value
      ?.where((c) => c.id == widget.conversationId)
      .firstOrNull;

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    setState(() {});
    ref.read(chatRoomProvider(widget.conversationId).notifier).send(text);
  }

  Future<void> _menu(_Menu m, Conversation? c) async {
    final path = reportNewPath(
      booking: c?.bookingId,
      conversation: widget.conversationId,
    );
    if (m == _Menu.report) {
      context.push(path);
      return;
    }
    final ok = await ConfirmDialog.show(
      context,
      title: 'Bagikan percakapan?',
      message:
          'Percakapan ini dibagikan lewat laporan masalah, dan hanya setelah '
          'Anda menyetujuinya. Lanjut membuat laporan?',
      confirmLabel: 'Lanjut',
    );
    if (ok && mounted) context.push(path);
  }

  void _maskedInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kenapa disamarkan?', style: context.text.h2),
              const SizedBox(height: AppSpace.s8),
              Text(
                'Demi keamanan, kontak pribadi disembunyikan sampai '
                'pembayaran dilakukan. Pembayaran lewat aplikasi melindungi '
                'dana Anda.',
                style: context.text.body,
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(label: 'Mengerti', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider.select((s) => s.user?.id));
    final room = ref.watch(chatRoomProvider(widget.conversationId));
    final c = _conversation;
    final other = c?.counterpart.name ?? 'Percakapan';
    final open = ref
        .watch(contactsOpenProvider(c?.bookingId))
        .maybeWhen(data: (v) => v, orElse: () => false);
    final t = context.tokens;
    return AppScaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(child: Text(other, overflow: TextOverflow.ellipsis)),
            if (c?.counterpart.verified ?? false) ...[
              const SizedBox(width: AppSpace.s8),
              const VerificationSeal(size: SealSize.sm, showLabel: false),
            ],
          ],
        ),
        actions: [
          PopupMenuButton<_Menu>(
            key: K.chatMenu,
            tooltip: 'Menu percakapan',
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (m) => _menu(m, c),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Menu.report, child: Text('Laporkan')),
              PopupMenuItem(
                value: _Menu.share,
                child: Text('Bagikan percakapan'),
              ),
            ],
          ),
        ],
      ),
      banner: (room.value?.reconnecting ?? false)
          ? Semantics(
              liveRegion: true,
              child: ColoredBox(
                color: t.warningContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s8),
                  child: Text(
                    'Menyambung kembali',
                    textAlign: TextAlign.center,
                    style: context.text.bodySm,
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: AsyncBody<ChatRoomState>(
              value: room,
              onRetry: () =>
                  ref.invalidate(chatRoomProvider(widget.conversationId)),
              data: (context, s) {
                final msgs = s.messages.reversed.toList();
                // Rata atas bila pesan sedikit; menempel bawah saat penuh.
                return Align(
                  alignment: Alignment.topCenter,
                  child: ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    itemCount: msgs.length + 1,
                    itemBuilder: (context, i) {
                      if (i == msgs.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.s8,
                          ),
                          child: open
                              ? const PrivacyNote(
                                  'Kontak pribadi kini dapat dibagikan.',
                                )
                              : _bannerClosed
                              ? const SizedBox.shrink()
                              : PrivacyNote(
                                  _privacyText,
                                  onTap: () =>
                                      setState(() => _bannerClosed = true),
                                ),
                        );
                      }
                      final m = msgs[i];
                      final mine = m.senderId == me;
                      final VoidCallback? tap = m.status == SendStatus.failed
                          ? () => ref
                                .read(
                                  chatRoomProvider(widget.conversationId)
                                      .notifier,
                                )
                                .retry(m.id)
                          : m.masked
                          ? _maskedInfo
                          : null;
                      final bubble = MessageBubble(
                        message: m,
                        mine: mine,
                        senderName: other,
                        onTap: tap,
                      );
                      final older = i + 1 < msgs.length ? msgs[i + 1] : null;
                      if (older != null &&
                          isSameWibDay(older.createdAt, m.createdAt)) {
                        return bubble;
                      }
                      return Column(
                        children: [DateDivider(m.createdAt), bubble],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (_contactLike.hasMatch(_input.text))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s4),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, size: 16, color: t.warning),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(
                    child: Text(
                      'Nomor atau tautan akan disamarkan di percakapan ini.',
                      style: context.text.caption.copyWith(color: t.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Tulis pesan',
                    child: TextField(
                      key: K.chatInput,
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: context.text.body,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan',
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                AppIconButton(
                  key: K.chatSend,
                  icon: LucideIcons.send,
                  label: 'Kirim pesan',
                  onPressed: _input.text.trim().isEmpty ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
