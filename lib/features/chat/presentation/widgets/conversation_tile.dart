import 'package:flutter/material.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

String _when(DateTime t) {
  final a = toWib(t);
  final n = toWib(DateTime.now());
  final same = a.year == n.year && a.month == n.month && a.day == n.day;
  return same ? formatTime(t) : formatDate(t);
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.c, required this.onTap});
  final Conversation c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final last = c.lastMessage;
    final at = c.lastAt;
    final name = c.counterpart.name;
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: [
        name,
        if (c.counterpart.verified) 'Terverifikasi',
        if (c.unread > 0) '${c.unread} pesan belum dibaca',
        ?last,
        if (at != null) _when(at),
      ].join(', '),
      child: InkWell(
        key: K.conversationTile(c.id),
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarImage(name: name, url: c.counterpart.photoUrl, size: 48),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: context.text.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.counterpart.verified) ...[
                            const SizedBox(width: AppSpace.s4),
                            const VerificationSeal(
                              size: SealSize.sm,
                              showLabel: false,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        last ?? 'Belum ada pesan',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.body.copyWith(
                          color: c.unread > 0 ? t.textPrimary : t.textMuted,
                          fontWeight: c.unread > 0 ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (at != null)
                      Text(_when(at), style: context.text.caption),
                    if (c.unread > 0) ...[
                      const SizedBox(height: AppSpace.s4),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.primary,
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s8,
                            vertical: AppSpace.s2,
                          ),
                          child: Text(
                            '${c.unread}',
                            style: context.text.caption.copyWith(
                              color: t.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}
