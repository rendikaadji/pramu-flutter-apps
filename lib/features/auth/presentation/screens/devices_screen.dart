import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/data/auth_providers.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

final devicesProvider = FutureProvider.autoDispose<List<Device>>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(authRepositoryProvider).devices();
}, retry: noRetry);

/// M-26 Perangkat masuk: daftar, terakhir aktif, cabut (perangkat ini = keluar).
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen>
    with ApiActionMixin {
  Future<void> _revoke(Device d) async {
    final ok = await ConfirmDialog.show(
      context,
      title: d.current
          ? 'Keluar dari perangkat ini?'
          : 'Keluarkan perangkat ini?',
      message: d.current
          ? 'Anda akan keluar dari akun dan perlu masuk lagi.'
          : '${d.name} akan keluar dari akun Anda. Pemilik perangkat perlu '
                'masuk lagi untuk memakainya.',
      confirmLabel: d.current ? 'Keluar' : 'Keluarkan',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref.read(authRepositoryProvider).revokeDevice(d.id),
      onConflict: () => ref.invalidate(devicesProvider),
    );
    if (!done || !mounted) return;
    if (d.current) {
      await ref.read(sessionProvider.notifier).logout();
    } else {
      ref.invalidate(devicesProvider);
      AppSnack.show(context, 'Perangkat sudah dikeluarkan.', success: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(devicesProvider);
    final t = context.tokens;
    return AppScaffold(
      title: 'Perangkat masuk',
      padded: false,
      body: AsyncBody<List<Device>>(
        value: value,
        onRetry: () => ref.invalidate(devicesProvider),
        data: (context, devices) {
          if (devices.isEmpty) {
            return const EmptyState(
              icon: LucideIcons.smartphone,
              title: 'Belum ada perangkat',
              message: 'Perangkat yang masuk ke akun Anda akan tampil di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(devicesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.s16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s16),
                  child: Text(
                    'Perangkat yang sedang masuk ke akun Anda. Keluarkan '
                    'perangkat yang tidak Anda kenali.',
                    style: context.text.body.copyWith(color: t.textMuted),
                  ),
                ),
                if (actionError != null) ActionErrorBox(error: actionError!),
                for (final d in [
                  ...devices.where((d) => d.current),
                  ...devices.where((d) => !d.current),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.smartphone, color: t.textMuted),
                              const SizedBox(width: AppSpace.s12),
                              Expanded(
                                child: Text(d.name, style: context.text.h3),
                              ),
                              if (d.current)
                                const StatusChip(
                                  label: 'Perangkat ini',
                                  tone: StatusTone.info,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'Terakhir aktif ${formatDateTime(d.lastActiveAt)}',
                            style: context.text.bodySm.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s8),
                          AppButton(
                            key: K.deviceRevoke(d.id),
                            label: d.current ? 'Keluar' : 'Keluarkan',
                            variant: AppButtonVariant.secondary,
                            expand: false,
                            onPressed: canAct ? () => _revoke(d) : null,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
