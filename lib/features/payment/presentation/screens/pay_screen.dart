import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/payment/data/payment_providers.dart';
import 'package:pramu_apps/features/payment/presentation/state/payment_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/money_hero_card.dart';
import 'package:pramu_apps/shared/app_ui/pinned_actions_bar.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';

/// M-74 Bayar period. Idempotency-Key dibuat sekali per niat dan dipakai ulang saat retry.
class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key, required this.periodId});
  final String periodId;

  @override
  ConsumerState<PayScreen> createState() => _State();
}

class _State extends ConsumerState<PayScreen> with ApiActionMixin {
  String _key = newIdempotencyKey();
  String? _localError;

  Future<void> _pay(BookingPeriod p) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Bayar ${formatRupiah(p.total)}?',
      message:
          'Uang ditahan aman dan baru dicairkan ke Asisten setelah pekerjaan '
          'selesai. Anda akan diarahkan ke halaman pembayaran.',
      confirmLabel: 'Bayar',
    );
    if (!ok || !mounted) return;
    setState(() => _localError = null);
    var opened = false;
    final done = await act(() async {
      try {
        final inv = await ref
            .read(paymentRepositoryProvider)
            .startPayment(widget.periodId, idempotencyKey: _key);
        opened = await openInvoiceUrl(ref.read(urlLauncherProvider), inv.url);
        if (!opened) {
          _localError = 'Halaman pembayaran tidak dapat dibuka. Coba lagi; Anda tidak akan ditagih dua kali.';
        }
      } on ApiException catch (e) {
        // Hasil pasti ditolak server -> niat baru; jaringan/5xx -> kunci sama.
        if (!e.isNetwork && e.status < 500) _key = newIdempotencyKey();
        rethrow;
      }
    }, onConflict: () => ref.invalidate(payPeriodProvider(widget.periodId)));
    if (!mounted || !done) return;
    if (opened) {
      context.pushReplacement(Routes.periodStatus(widget.periodId));
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(payPeriodProvider(widget.periodId));
    final period = value.value;
    final payable = period != null && period.status.canPay;
    return AppScaffold(
      title: 'Bayar periode',
      glow: true,
      bottomNavigationBar: payable
          ? PinnedActionsBar(
              children: [
                AppButton(
                  key: K.payButton,
                  label: 'Bayar ${formatRupiah(period.total)}',
                  icon: LucideIcons.lock,
                  large: true,
                  loading: busy,
                  onPressed: canAct ? () => _pay(period) : null,
                ),
              ],
            )
          : null,
      body: AsyncBody<BookingPeriod>(
        value: value,
        onRetry: () => ref.invalidate(payPeriodProvider(widget.periodId)),
        data: (context, p) => SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpace.s8,
            bottom: AppSpace.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContractSummary(bookingId: p.bookingId, period: p),
              _Breakdown(p: p),
              const SizedBox(height: AppSpace.s16),
              MoneyHeroCard(
                label: 'Total pembayaran',
                amount: formatRupiah(p.total),
                semanticsLabel: 'Total: ${formatRupiah(p.total)}',
              ),
              const SizedBox(height: AppSpace.s16),
              const _HeldSeal(),
              const SizedBox(height: AppSpace.s16),
              if (actionError != null) ActionErrorBox(error: actionError!),
              if (_localError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s16),
                  child: Semantics(
                    liveRegion: true,
                    child: FieldErrorText(_localError!),
                  ),
                ),
              if (!p.status.canPay)
                EmptyState(
                  compact: true,
                  title: p.status.labelFor(
                    ref.read(sessionProvider).activeRole ?? Role.seeker,
                  ),
                  message: 'Periode ini tidak dapat dibayar saat ini.',
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

/// Ringkasan kontrak (judul + lawan kontrak + periode). Tanpa data kontrak,
/// hanya periode dan rentang tanggal.
class _ContractSummary extends ConsumerWidget {
  const _ContractSummary({required this.bookingId, required this.period});
  final String bookingId;
  final BookingPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(bookingProvider(bookingId)).value;
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b != null) ...[
              Row(
                children: [
                  AvatarImage(
                    name: b.assistant.name,
                    url: b.assistant.photoUrl,
                    size: 48,
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.listingTitle, style: context.text.h3),
                        const SizedBox(height: AppSpace.s2),
                        Text(
                          'Dengan ${b.assistant.name}',
                          style: context.text.bodySm.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
                child: Divider(height: 1, color: t.borderSubtle),
              ),
            ],
            Text('Periode ${period.index}', style: context.text.h2),
            const SizedBox(height: AppSpace.s2),
            Text(
              '${formatDate(period.start)} - ${formatDate(period.end)}',
              style: context.text.body.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rincian nominal + biaya layanan (total ada di kartu hero di bawahnya).
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.p});
  final BookingPeriod p;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian pembayaran', style: context.text.label),
          const SizedBox(height: AppSpace.s8),
          FeeBreakdown(
            rows: [
              FeeRow('Gaji periode ${p.index}', formatRupiah(p.amount)),
              FeeRow('Biaya layanan', formatRupiah(p.serviceFee)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Segel "Dana ditahan aman": penegas kepercayaan sebelum bayar.
class _HeldSeal extends StatelessWidget {
  const _HeldSeal();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.successContainer,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: t.success.withValues(alpha: .4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ExcludeSemantics(child: MoneySafeIllustration(size: 72)),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dana ditahan aman', style: context.text.h3),
                    const SizedBox(height: AppSpace.s2),
                    Text(
                      'Uang Anda ditahan aman dan baru dicairkan ke asisten '
                      'setelah pekerjaan selesai.',
                      style: context.text.bodySm.copyWith(color: t.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
