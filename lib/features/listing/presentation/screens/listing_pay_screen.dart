import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';

/// M-34 Bayar fee lowongan. Sumber kebenaran = status server (dicek ulang),
/// bukan parameter URL/callback pembayaran.
class ListingPayScreen extends ConsumerStatefulWidget {
  const ListingPayScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ListingPayScreen> createState() => _State();
}

class _State extends ConsumerState<ListingPayScreen>
    with ApiActionMixin, WidgetsBindingObserver {
  static const _interval = Duration(seconds: 3);
  static const _maxChecks = 20;

  /// Idempotency-Key per niat bayar: dipakai ulang saat retry jaringan/5xx.
  String _key = newIdempotencyKey();
  Invoice? _invoice;
  bool _waiting = false;
  bool _timedOut = false;
  int _checks = 0;
  bool _checking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waiting) _check();
  }

  Future<void> _open() async {
    final ok = await openInvoiceUrl(
      ref.read(urlLauncherProvider),
      _invoice?.url,
    );
    if (!ok) {
      throw ApiException(
        status: 400,
        code: 'INVOICE_URL_INVALID',
        message: 'Tautan pembayaran tidak dapat dibuka. Coba lagi nanti.',
      );
    }
  }

  Future<void> _pay() async {
    final done = await act(() async {
      final inv = _invoice;
      final fresh =
          inv == null ||
          (inv.expiresAt != null && inv.expiresAt!.isBefore(DateTime.now()));
      if (fresh) {
        try {
          _invoice = await ref
              .read(listingRepositoryProvider)
              .pay(widget.id, idempotencyKey: _key);
          _key = newIdempotencyKey(); // niat selesai; tagihan baru = kunci baru
        } on ApiException catch (e) {
          // ditolak pasti -> niat baru; jaringan/5xx -> kunci sama
          if (!e.isNetwork && e.status < 500) _key = newIdempotencyKey();
          rethrow;
        }
      }
      await _open();
    }, onConflict: () => ref.invalidate(listingDetailProvider(widget.id)));
    if (done && mounted) _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    setState(() {
      _waiting = true;
      _timedOut = false;
      _checks = 0;
    });
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final l = await ref.read(listingRepositoryProvider).get(widget.id);
      if (!mounted) return;
      if (l.status == ListingStatus.open) {
        _timer?.cancel();
        ref.invalidate(listingDetailProvider(widget.id));
        ref.invalidate(myListingsProvider);
        setState(() => _waiting = false);
        return;
      }
      if (++_checks >= _maxChecks) {
        _timer?.cancel();
        setState(() => _timedOut = true);
      }
    } catch (_) {
      // jaringan putus: biarkan polling berikutnya mencoba lagi
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDetailProvider(widget.id));
    return AppScaffold(
      title: 'Bayar fee lowongan',
      body: AsyncBody<Listing>(
        value: async,
        onRetry: () => ref.invalidate(listingDetailProvider(widget.id)),
        data: (ctx, l) => SingleChildScrollView(child: _content(ctx, l)),
      ),
    );
  }

  Widget _content(BuildContext context, Listing l) {
    final t = context.tokens;
    if (l.status == ListingStatus.open) {
      final until = l.expiresAt;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: AppCard(
              color: t.successContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.circleCheck, color: t.success),
                      const SizedBox(width: AppSpace.s8),
                      Expanded(
                        child: Text(
                          'Lowongan sudah tayang',
                          style: context.text.h3,
                        ),
                      ),
                    ],
                  ),
                  if (until != null) ...[
                    const SizedBox(height: AppSpace.s8),
                    Text('Tayang sampai ${formatDate(until)}.'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Lihat lowongan',
            onPressed: () =>
                context.pushReplacement(Routes.listingManage(l.id)),
          ),
        ],
      );
    }
    if (!l.status.canPay) {
      return EmptyBlock(
        message:
            'Lowongan ini berstatus "${l.status.label}" dan tidak dapat dibayar.',
      );
    }
    final fee = formatRupiah(l.postingFee);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actionError != null)
          ActionErrorBox(error: actionError!, skckListingId: null),
        Text(l.title, style: context.text.h2),
        const SizedBox(height: AppSpace.s16),
        AppCard(
          child: FeeBreakdown(
            rows: [FeeRow('Biaya pasang (tayang 30 hari)', fee, total: true)],
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        Text(
          'Biaya pasang tidak dikembalikan jika tidak ada kecocokan.',
          style: context.text.bodySm.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: AppSpace.s24),
        if (_waiting) ...[
          Semantics(
            liveRegion: true,
            child: AppCard(
              key: K.paymentChecking,
              color: t.warningContainer,
              child: Text(
                _timedOut
                    ? 'Pembayaran belum kami terima. Jika sudah membayar, ketuk Cek status pembayaran.'
                    : 'Pembayaran sedang diproses. Jangan bayar lagi; kami kabari begitu selesai.',
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.listingPayCheck,
            label: 'Cek status pembayaran',
            onPressed: _check,
          ),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            label: 'Buka halaman pembayaran lagi',
            variant: AppButtonVariant.secondary,
            loading: busy,
            onPressed: canAct ? _pay : null,
          ),
        ] else
          AppButton(
            key: K.listingPay,
            label: 'Bayar $fee',
            large: true,
            loading: busy,
            onPressed: canAct ? _pay : null,
          ),
      ],
    );
  }
}

/// Pesan sederhana di tengah untuk kondisi akhir.
class EmptyBlock extends StatelessWidget {
  const EmptyBlock({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.s32),
    child: Text(message, style: context.text.body, textAlign: TextAlign.center),
  );
}
