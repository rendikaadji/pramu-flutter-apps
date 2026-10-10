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
import 'package:pramu_apps/features/payment/data/payment_providers.dart';
import 'package:pramu_apps/features/payment/presentation/state/payment_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
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
    return AppScaffold(
      title: 'Bayar periode',
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
                rows: [
                  FeeRow('Gaji periode ${p.index}', formatRupiah(p.amount)),
                  FeeRow('Biaya layanan', formatRupiah(p.serviceFee)),
                  FeeRow('Total', formatRupiah(p.total), total: true),
                ],
              ),
              const SizedBox(height: AppSpace.s12),
              const PrivacyNote(
                'Uang Anda ditahan aman dan baru dicairkan ke asisten setelah pekerjaan selesai.',
              ),
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
                  icon: LucideIcons.info,
                  title: p.status.labelFor(
                    ref.read(sessionProvider).activeRole ?? Role.seeker,
                  ),
                  message: 'Periode ini tidak dapat dibayar saat ini.',
                  actionLabel: 'Kembali',
                  onAction: () => context.pop(),
                )
              else
                AppButton(
                  key: K.payButton,
                  label: 'Bayar ${formatRupiah(p.total)}',
                  large: true,
                  loading: busy,
                  onPressed: canAct ? () => _pay(p) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
