import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

bool isSameWibDay(DateTime a, DateTime b) {
  final x = toWib(a);
  final y = toWib(b);
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Pemisah tanggal di ruang chat: "Hari ini" / "Kemarin" / tanggal.
class DateDivider extends StatelessWidget {
  const DateDivider(this.at, {super.key});
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final now = DateTime.now();
    final label = isSameWibDay(at, now)
        ? 'Hari ini'
        : isSameWibDay(at, now.subtract(const Duration(days: 1)))
        ? 'Kemarin'
        : formatDate(at);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
      child: Center(
        child: Semantics(
          header: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.sunken,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: t.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s12,
                vertical: AppSpace.s4,
              ),
              child: Text(
                label,
                style: context.text.caption.copyWith(color: t.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gelembung teks polos (tanpa HTML/markdown). Teks tersamar tampil apa adanya dari server.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.senderName,
    this.onTap,
  });

  final ChatMessage message;
  final bool mine;
  final String senderName;

  /// gagal -> ulangi; tersamar -> penjelas.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final m = message;
    final failed = m.status == SendStatus.failed;
    final (statusIcon, statusLabel) = !mine
        ? (null, null)
        : switch (m.status) {
            SendStatus.sending => (LucideIcons.clock, m.status.label),
            SendStatus.failed => (LucideIcons.circleAlert, m.status.label),
            SendStatus.sent when m.readAt != null => (
              LucideIcons.checkCheck,
              'Dibaca',
            ),
            SendStatus.sent => (LucideIcons.check, m.status.label),
          };
    final time = formatTime(m.createdAt);
    final who = mine ? 'Anda' : senderName;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: mine ? t.primary : t.sunken,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(mine ? AppRadius.lg : AppRadius.xs),
          bottomRight: Radius.circular(mine ? AppRadius.xs : AppRadius.lg),
        ),
        border: failed
            ? Border.all(color: t.danger, width: 1.5)
            : mine
            ? null
            : Border.all(color: t.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: context.text.body.copyWith(
                color: mine ? t.onPrimary : t.textPrimary,
              ),
            ),
            if (m.masked) ...[
              const SizedBox(height: AppSpace.s4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 16,
                    color: mine ? t.onPrimary : t.textMuted,
                  ),
                  const SizedBox(width: AppSpace.s4),
                  Flexible(
                    child: Text(
                      'Kontak disamarkan',
                      style: context.text.caption.copyWith(
                        color: mine ? t.onPrimary : t.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: onTap != null,
      onTap: onTap,
      label:
          'Dari $who, $time, ${statusLabel ?? ''}, '
          '${m.masked ? 'Nomor disembunyikan' : m.text}',
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, c) => ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth * .82),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Column(
                crossAxisAlignment: mine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  onTap == null
                      ? bubble
                      : InkWell(
                          key: K.messageBubble(m.id),
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: AppSpace.tap,
                            ),
                            child: bubble,
                          ),
                        ),
                  const SizedBox(height: AppSpace.s2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: context.text.caption),
                      if (statusIcon != null) ...[
                        const SizedBox(width: AppSpace.s4),
                        Icon(
                          statusIcon,
                          size: 14,
                          color: failed ? t.danger : t.textMuted,
                        ),
                        const SizedBox(width: AppSpace.s4),
                        Flexible(
                          child: Text(
                            statusLabel!,
                            style: context.text.caption.copyWith(
                              color: failed ? t.danger : t.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
