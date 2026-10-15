import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/payment/presentation/state/payment_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/status_hero_panel.dart';

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
  const _Checking({this.onRecheck, this.period});
  final VoidCallback? onRecheck;
  final BookingPeriod? period;

  @override
  Widget build(BuildContext context) => _StatusLayout(
    semanticsKey: K.paymentChecking,
    semanticsLabel: 'Memeriksa pembayaran',
    hero: StatusHeroPanel(
      icon: LucideIcons.hourglass,
      tone: StatusTone.info,
      title: 'Memeriksa pembayaran',
      message: 'Kami sedang memastikan pembayaran Anda. Halaman ini bisa tetap dibuka.',
      footer: period == null ? null : _PeriodSummary(period!),
    ),
    actions: [
      if (onRecheck != null)
        AppButton(
          label: 'Cek sekarang',
          variant: AppButtonVariant.secondary,
          onPressed: onRecheck,
        ),
    ],
  );
}

/// Hero di tengah (bisa di-scroll), aksi menempel di bawah isi.
class _StatusLayout extends StatelessWidget {
  const _StatusLayout({
    required this.hero,
    required this.actions,
    this.semanticsKey,
    this.semanticsLabel,
  });
  final Widget hero;
  final List<Widget> actions;
  final Key? semanticsKey;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            child: Semantics(
              key: semanticsKey,
              liveRegion: true,
              container: true,
              label: semanticsLabel,
              child: hero,
            ),
          ),
        ),
      ),
      for (final a in actions) ...[a, const SizedBox(height: AppSpace.s8)],
      const SizedBox(height: AppSpace.s8),
    ],
  );
}

/// Ringkasan periode di bawah status: periode, rentang tanggal, nominal.
class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary(this.p);
  final BookingPeriod p;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Periode ${p.index}', style: context.text.h3),
                const SizedBox(height: AppSpace.s2),
                Text(
                  '${formatDate(p.start)} - ${formatDate(p.end)}',
                  style: context.text.bodySm.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          MoneyText(formatRupiah(p.total)),
        ],
      ),
    );
  }
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
      return _Checking(onRecheck: onRecheck, period: p);
    }
    final pending = p.status.canPay;
    final (icon, tone, title, message) = switch (p.status) {
      _ when pending => (
        LucideIcons.hourglass,
        StatusTone.warning,
        'Pembayaran sedang diproses',
        'Anda tidak perlu membayar lagi. Kami kabari begitu selesai. '
            'Belum membayar? Buka kontrak untuk melanjutkan.',
      ),
      PeriodStatus.expired => (
        LucideIcons.circleX,
        StatusTone.danger,
        'Tagihan kedaluwarsa',
        'Batas waktu pembayaran sudah lewat. Buka kontrak untuk melihat langkah berikutnya.',
      ),
      PeriodStatus.cancelled || PeriodStatus.refunded => (
        LucideIcons.ban,
        StatusTone.neutral,
        'Dibatalkan',
        'Periode ini dibatalkan.',
      ),
      PeriodStatus.disputed => (
        LucideIcons.triangleAlert,
        StatusTone.warning,
        'Sedang ditinjau',
        'Tim kami sedang meninjau periode ini.',
      ),
      PeriodStatus.unknown => (
        LucideIcons.info,
        StatusTone.neutral,
        'Status belum bisa dibaca',
        'Buka kontrak untuk melihat kabar terbaru.',
      ),
      _ => (
        LucideIcons.circleCheck,
        StatusTone.success,
        'Pembayaran diterima',
        'Dana ditahan aman sampai periode selesai.',
      ),
    };
    if (tone == StatusTone.success) {
      // Lunas hanya dari status server (state paid), bukan dari parameter return.
      return Semantics(
        key: K.periodStatus,
        container: true,
        child: SuccessView(
          title: title,
          message: '$message\nPeriode ${p.index}: ${formatRupiah(p.total)}',
          actionLabel: 'Lihat kontrak',
          onAction: () => onContract(p.bookingId),
        ),
      );
    }
    return _StatusLayout(
      semanticsKey: pending ? K.paymentPending : K.periodStatus,
      hero: StatusHeroPanel(
        icon: icon,
        tone: tone,
        title: title,
        message: message,
        footer: _PeriodSummary(p),
      ),
      actions: [
        if (pending)
          AppButton(
            label: 'Cek status',
            variant: AppButtonVariant.secondary,
            onPressed: onRecheck,
          ),
        AppButton(
          label: 'Lihat kontrak',
          onPressed: () => onContract(p.bookingId),
        ),
      ],
    );
  }
}
