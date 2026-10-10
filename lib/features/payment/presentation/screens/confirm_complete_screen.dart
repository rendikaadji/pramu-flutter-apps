import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/payment/data/payment_providers.dart';
import 'package:pramu_apps/features/payment/presentation/state/payment_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/report_path.dart';

/// M-76 Konfirmasi selesai (Pencari).
class ConfirmCompleteScreen extends ConsumerStatefulWidget {
  const ConfirmCompleteScreen({super.key, required this.periodId});
  final String periodId;

  @override
  ConsumerState<ConfirmCompleteScreen> createState() => _State();
}

class _State extends ConsumerState<ConfirmCompleteScreen> with ApiActionMixin {
  Future<void> _confirm(BookingPeriod p) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Konfirmasi selesai?',
      message:
          'Dana ${formatRupiah(p.amount)} akan dicairkan ke Pelamar. '
          'Setelah dikonfirmasi, dana tidak bisa ditarik kembali.',
      confirmLabel: 'Konfirmasi selesai',
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref.read(paymentRepositoryProvider).confirmComplete(p.id),
      onConflict: () => ref.invalidate(payPeriodProvider(widget.periodId)),
    );
    if (!mounted || !done) return;
    AppSnack.show(
      context,
      'Terima kasih. Dana sudah dicairkan ke Pelamar.',
      success: true,
    );
    context.canPop()
        ? context.pop(true)
        : context.go(Routes.bookingDetail(p.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(payPeriodProvider(widget.periodId));
    return AppScaffold(
      title: 'Konfirmasi selesai',
      body: AsyncBody<BookingPeriod>(
        value: value,
        onRetry: () => ref.invalidate(payPeriodProvider(widget.periodId)),
        data: (context, p) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Periode ${p.index}', style: context.text.h1),
              Text(
                '${formatDate(p.start)} - ${formatDate(p.end)}',
                style: context.text.body.copyWith(
                  color: context.tokens.textMuted,
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              FeeBreakdown(
                rows: [FeeRow('Gaji periode', formatRupiah(p.amount))],
              ),
              const SizedBox(height: AppSpace.s16),
              if (actionError != null) ActionErrorBox(error: actionError!),
              if (p.status.canConfirmComplete) ...[
                Text('Apakah pekerjaan sudah sesuai?', style: context.text.h2),
                const SizedBox(height: AppSpace.s8),
                if (p.autoReleaseAt != null) _AutoRelease(at: p.autoReleaseAt!),
                const SizedBox(height: AppSpace.s16),
                AppButton(
                  key: K.confirmComplete,
                  label: 'Konfirmasi selesai',
                  large: true,
                  loading: busy,
                  onPressed: canAct ? () => _confirm(p) : null,
                ),
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  key: K.confirmReport,
                  label: 'Laporkan masalah',
                  icon: LucideIcons.flag,
                  variant: AppButtonVariant.secondary,
                  onPressed: busy
                      ? null
                      : () => context.push(
                          reportNewPath(booking: p.bookingId, period: p.id),
                        ),
                ),
              ] else
                EmptyState(
                  icon: LucideIcons.info,
                  title: 'Belum waktunya dikonfirmasi',
                  message:
                      'Status periode: ${p.status.labelFor(Role.seeker)}. '
                      'Konfirmasi tersedia setelah periode selesai dijalankan.',
                  actionLabel: 'Kembali',
                  onAction: () => context.pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teks auto-release + sisa waktu (diperbarui tiap menit).
class _AutoRelease extends StatefulWidget {
  const _AutoRelease({required this.at});
  final DateTime at;

  @override
  State<_AutoRelease> createState() => _AutoReleaseState();
}

class _AutoReleaseState extends State<_AutoRelease> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(minutes: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.at.difference(DateTime.now().toUtc());
    final remain = left.isNegative
        ? 'Dana segera dicairkan.'
        : left.inHours >= 1
        ? 'Sisa ${left.inHours} jam ${left.inMinutes % 60} menit.'
        : 'Sisa ${left.inMinutes} menit.';
    return PrivacyNote(
      'Jika tidak Anda konfirmasi, dana otomatis dicairkan pada '
      '${formatDateTime(widget.at)}. $remain',
    );
  }
}
