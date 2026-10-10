import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/notification/data/push_providers.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/notification/domain/push_service.dart';
import 'package:pramu_apps/features/notification/presentation/state/notification_state.dart';
import 'package:pramu_apps/features/notification/presentation/widgets/notification_tile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-23 Notifikasi.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  /// Tandai dibaca, ganti peran bila perlu, lalu buka rute allowlist. Tipe/ID palsu -> tetap di sini.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(notificationsProvider.notifier);
    final session = ref.read(sessionProvider.notifier);
    final user = ref.read(sessionProvider).user;
    final route = n.route;
    try {
      await notifier.markRead(n.id);
    } on ApiException {
      // gagal menandai tidak menghalangi membuka
    }
    if (route == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Notifikasi ini tidak dapat dibuka.')),
      );
      return;
    }
    final role = n.role;
    if (role != null && user != null && role != user.activeRole) {
      if (!user.roles.contains(role)) {
        messenger.showSnackBar(
          SnackBar(content: Text('Notifikasi ini untuk peran ${role.label}.')),
        );
        return;
      }
      try {
        await session.switchRole(role);
      } on ApiException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Sekarang sebagai ${role.label}')),
      );
    }
    await router.push<void>(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationsProvider);
    final push = ref.watch(pushServiceProvider);
    final perm = ref.watch(pushPermissionProvider).value;
    final n = ref.read(notificationsProvider.notifier);

    Widget? banner;
    if (push.available && perm == PushPermission.notDetermined) {
      banner = PermissionRationaleCard(
        icon: LucideIcons.bell,
        title: 'Aktifkan notifikasi',
        message: 'Kami kabari saat ada pelamar baru, pesan, atau pembayaran. Anda bisa mematikannya kapan saja.',
        primaryLabel: 'Aktifkan notifikasi',
        onPrimary: () => ref.read(pushPermissionProvider.notifier).request(),
      );
    } else if (push.available && perm == PushPermission.denied) {
      banner = PermissionRationaleCard(
        icon: LucideIcons.bellOff,
        title: 'Izin notifikasi dimatikan',
        message: 'Aktifkan di Pengaturan agar tidak ketinggalan kabar penting.',
        primaryLabel: 'Buka Pengaturan',
        onPrimary: push.openSettings,
        denied: true,
      );
    }

    return AppScaffold(
      title: 'Notifikasi',
      body: s.when(
        loading: () => Semantics(
          label: 'Memuat',
          child: const Column(
            children: [
              SizedBox(height: AppSpace.s16),
              AppSkeleton.box(72),
              SizedBox(height: AppSpace.s12),
              AppSkeleton.box(72),
              SizedBox(height: AppSpace.s12),
              AppSkeleton.box(72),
            ],
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.only(top: AppSpace.s16),
          child: ApiErrorView(
            error: asApiException(e),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        ),
        data: (d) {
          final (today, earlier) = d.grouped(DateTime.now().toUtc());
          Widget group(String title, List<AppNotification> l, bool isToday) =>
              l.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title),
                    for (final x in l) ...[
                      NotificationTile(
                        x,
                        key: K.notificationTile(x.id),
                        today: isToday,
                        onTap: () => _open(context, ref, x),
                      ),
                      const Divider(height: 1, indent: 52),
                    ],
                  ],
                );
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await ref.read(notificationsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
              children: [
                if (banner != null) ...[
                  banner,
                  const SizedBox(height: AppSpace.s16),
                ],
                if (d.items.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: EmptyState(
                      icon: LucideIcons.bell,
                      title: 'Belum ada notifikasi',
                      message: 'Kabar penting akan muncul di sini.',
                    ),
                  )
                else ...[
                  if (d.hasUnread)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton(
                        key: K.notificationMarkAll,
                        label: 'Tandai semua dibaca',
                        icon: LucideIcons.checkCheck,
                        variant: AppButtonVariant.text,
                        expand: false,
                        onPressed: n.markAllRead,
                      ),
                    ),
                  group('Hari ini', today, true),
                  group('Sebelumnya', earlier, false),
                  if (d.nextCursor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s16),
                      child: AppButton(
                        label: 'Muat lebih banyak',
                        variant: AppButtonVariant.secondary,
                        onPressed: n.loadMore,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
