import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/payment/data/payment_providers.dart';
import 'package:pramu_apps/features/payment/domain/payment_repository.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

/// M-74 / M-76: period (angka dari server).
final payPeriodProvider = FutureProvider.autoDispose
    .family<BookingPeriod, String>((ref, id) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(bookingRepositoryProvider).period(id);
    }, retry: noRetry);

/// M-77: pratinjau refund dari server.
final cancelPreviewProvider = FutureProvider.autoDispose
    .family<RefundPreview, String>((ref, bookingId) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(paymentRepositoryProvider).cancelPreview(bookingId);
    }, retry: noRetry);

/// Hasil pemeriksaan: [polling] true selama masih menunggu dan batas polling belum habis.
class PaymentCheck {
  const PaymentCheck(this.period, {required this.polling});
  final BookingPeriod period;
  final bool polling;
}

/// M-75. SELALU memanggil API (`checkStatus`); tidak pernah menyimpulkan lunas dari URL/deep link.
class PaymentStatusNotifier extends AsyncNotifier<PaymentCheck> {
  PaymentStatusNotifier(this.periodId);
  final String periodId;

  static const interval = Duration(seconds: 5);
  static const maxPolls =
      24; // ~2 menit; setelahnya pengguna menekan "Cek status"

  int _polls = 0;
  Timer? _timer;

  @override
  Future<PaymentCheck> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    ref.onDispose(() => _timer?.cancel());
    _polls = 0;
    return _check();
  }

  Future<PaymentCheck> _check() async {
    final p = await ref.read(paymentRepositoryProvider).checkStatus(periodId);
    final polling = p.status.canPay && _polls < maxPolls;
    _timer?.cancel();
    if (polling) _timer = Timer(interval, _tick);
    return PaymentCheck(p, polling: polling);
  }

  /// Putaran otomatis. `_polls` tidak direset di sini, jadi batas `maxPolls`
  /// berlaku juga saat jaringan putus.
  Future<void> _tick() async {
    if (!ref.mounted) return;
    _polls++;
    try {
      final next = await _check();
      if (ref.mounted) state = AsyncData(next);
    } on Exception {
      if (!ref.mounted) return;
      if (_polls < maxPolls) {
        _timer = Timer(interval, _tick);
        return;
      }
      // batas habis: berhenti; pengguna menekan "Cek status"
      final last = state.value;
      if (last != null) {
        state = AsyncData(PaymentCheck(last.period, polling: false));
      }
    }
  }

  /// "Cek status" manual atau app dibuka kembali.
  Future<void> refresh() async {
    _polls = 0;
    final next = await AsyncValue.guard(_check);
    if (ref.mounted) state = next;
  }
}

final paymentStatusProvider = AsyncNotifierProvider.autoDispose
    .family<PaymentStatusNotifier, PaymentCheck, String>(
      PaymentStatusNotifier.new,
      retry: noRetry,
    );
