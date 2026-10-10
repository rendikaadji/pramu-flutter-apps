import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

IconData _icon(NotificationType t) => switch (t) {
  NotificationType.verification => LucideIcons.shieldCheck,
  NotificationType.application => LucideIcons.fileText,
  NotificationType.interview => LucideIcons.calendar,
  NotificationType.chat => LucideIcons.messageCircle,
  NotificationType.agreement => LucideIcons.handshake,
  NotificationType.booking => LucideIcons.briefcase,
  NotificationType.payment => LucideIcons.wallet,
  NotificationType.rating => LucideIcons.star,
  NotificationType.report => LucideIcons.flag,
  NotificationType.unknown => LucideIcons.bell,
};

/// Baris notifikasi: ikon jenis, judul, isi, waktu, titik belum dibaca (plus teks untuk pembaca layar).
class NotificationTile extends StatelessWidget {
  const NotificationTile(this.n, {super.key, required this.onTap, this.today});

  final AppNotification n;
  final VoidCallback onTap;
  final bool? today;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final time = today == true
        ? formatTime(n.createdAt)
        : formatDate(n.createdAt);
    return Semantics(
      button: true,
      label: '${n.unread ? 'Belum dibaca. ' : ''}${n.title}. ${n.body}. $time',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _icon(n.type),
                  size: 24,
                  color: n.unread ? t.primary : t.textMuted,
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: context.text.label.copyWith(
                          fontWeight: n.unread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s2),
                      Text(
                        n.body,
                        style: context.text.bodySm.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        time,
                        style: context.text.caption.copyWith(
                          color: t.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (n.unread) ...[
                  const SizedBox(width: AppSpace.s8),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: AppSpace.s8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
