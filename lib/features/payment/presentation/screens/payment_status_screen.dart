import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/payment/presentation/state/payment_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-75 Status pembayaran. Status selalu dari API; parameter return/deep link hanya pemicu.
class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({super.key, required this.periodId});
  final String periodId;

  @override
  ConsumerState<PaymentStatusScreen> createState() => _State();
}

class _State extends ConsumerState<PaymentStatusScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App dibuka lagi (mis. selesai membayar di browser) -> periksa ulang ke server.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _recheck();
  }

  void _recheck() =>
      ref.read(paymentStatusProvider(widget.periodId).notifier).refresh();

  void _openContract(String bookingId) {
    final role = ref.read(sessionProvider).activeRole ?? Role.seeker;
    context.go(Routes.home(role));
    context.push(Routes.bookingDetail(bookingId));
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(paymentStatusProvider(widget.periodId));
    return AppScaffold(
      title: 'Status pembayaran',
      body: value.hasValue
          ? _Result(
              check: value.requireValue,
              onRecheck: _recheck,
              onContract: _openContract,
            )
          : value.hasError
          ? SingleChildScrollView(
              child: ApiErrorView(
                error: asApiException(value.error!),
                onRetry: _recheck,
              ),
            )
          : const _Checking(),
    );
  }
}

class _Checking extends StatelessWidget {
  const _Checking({this.onRecheck});
  final VoidCallback? onRecheck;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      key: K.paymentChecking,
      liveRegion: true,
      container: true,
      label: 'Memeriksa pembayaran',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpace.s24),
          Text('Memeriksa pembayaran', style: context.text.h2),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Mohon tunggu. Jangan tutup halaman ini.',
            textAlign: TextAlign.center,
            style: context.text.body.copyWith(color: context.tokens.textMuted),
          ),
          if (onRecheck != null) ...[
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Cek sekarang',
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: onRecheck,
            ),
          ],
        ],
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({
    required this.check,
    required this.onRecheck,
    required this.onContract,
  });
  final PaymentCheck check;
  final VoidCallback onRecheck;
  final void Function(String bookingId) onContract;

  @override
  Widget build(BuildContext context) {
    final p = check.period;
    if (p.status.canPay && check.polling) {
      return _Checking(onRecheck: onRecheck);
    }
    final t = context.tokens;
    final pending = p.status.canPay;
    final (icon, color, title, message) = switch (p.status) {
      _ when pending => (
        LucideIcons.hourglass,
        t.warning,
        'Pembayaran sedang diproses',
        'Jangan bayar lagi; kami kabari begitu selesai. '
            'Belum membayar? Buka kontrak untuk membayar.',
      ),
      PeriodStatus.expired => (
        LucideIcons.circleX,
        t.danger,
        'Tagihan kedaluwarsa',
        'Batas waktu pembayaran sudah lewat. Buka kontrak untuk langkah berikutnya.',
      ),
      PeriodStatus.cancelled || PeriodStatus.refunded => (
        LucideIcons.ban,
        t.textMuted,
        'Dibatalkan',
        'Periode ini dibatalkan.',
      ),
      PeriodStatus.disputed => (
        LucideIcons.triangleAlert,
        t.warning,
        'Sedang ditinjau',
        'Tim kami sedang meninjau periode ini.',
      ),
      PeriodStatus.unknown => (
        LucideIcons.info,
        t.textMuted,
        'Status belum dikenal',
        'Buka kontrak untuk melihat rincian terbaru.',
      ),
      _ => (
        LucideIcons.circleCheck,
        t.success,
        'Pembayaran diterima',
        'Dana ditahan aman sampai periode selesai.',
      ),
    };
    return Center(
      child: SingleChildScrollView(
        child: Semantics(
          key: pending ? K.paymentPending : K.periodStatus,
          liveRegion: true,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: AppSpace.s16),
              Text(title, style: context.text.h2, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.s8),
              Text(
                message,
                style: context.text.body.copyWith(color: t.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.s24),
              if (pending) ...[
                AppButton(
                  label: 'Cek status',
                  variant: AppButtonVariant.secondary,
                  onPressed: onRecheck,
                ),
                const SizedBox(height: AppSpace.s8),
              ],
              AppButton(
                label: 'Lihat kontrak',
                onPressed: () => onContract(p.bookingId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
