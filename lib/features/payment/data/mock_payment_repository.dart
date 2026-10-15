import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/payment/domain/payment_repository.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';

/// Tagihan dibuat oleh `startPayment`; period jadi `paid` HANYA setelah `checkStatus` ke-2 (webhook mock).
class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository(this._b);
  final MockBackend _b;

  BookingPeriod _period(String id, {bool seekerOnly = false}) {
    final p =
        _b.periods[id] ?? apiFail(404, 'NOT_FOUND', 'Periode tidak ditemukan.');
    final b = _b.booking(p.bookingId); // cek keanggotaan + langkah otomatis
    if (seekerOnly && b.seeker.id != _b.me.id) {
      apiFail(403, 'FORBIDDEN', 'Hanya pencari yang dapat melakukan ini.');
    }
    return _b.periods[id]!;
  }

  @override
  Future<Invoice> startPayment(
    String periodId, {
    required String idempotencyKey,
  }) => _b.run(() {
    final p = _period(periodId, seekerOnly: true);
    final existing = _b.invoiceByKey[idempotencyKey];
    final inv =
        _b.invoices[existing] ??
        (() {
          if (!p.status.canPay) {
            apiFail(
              409,
              'PERIOD_INVALID_STATE',
              'Status tagihan sudah berubah.',
            );
          }
          final i = MockInvoice(_b.newId(), 'period', periodId, p.total);
          _b.invoices[i.id] = i;
          _b.invoiceByKey[idempotencyKey] = i.id;
          _b.periods[periodId] = p.copyWith(invoiceId: i.id);
          return i;
        })();
    return Invoice(
      id: inv.id,
      url: 'https://checkout.xendit.co/web/${inv.id}',
      amount: inv.amount,
      expiresAt: _b.now().add(const Duration(hours: 24)),
    );
  });

  @override
  Future<BookingPeriod> checkStatus(String periodId) => _b.run(() {
    final p = _period(periodId);
    final inv = _b.invoices[p.invoiceId];
    if (p.status == PeriodStatus.awaitingPayment &&
        inv != null &&
        ++inv.checks >= 2) {
      final paid = p.copyWith(status: PeriodStatus.paid, paidAt: _b.now());
      _b.periods[periodId] = paid;
      final b = _b.bookings[p.bookingId]!;
      _b.notify(
        b.assistant.id,
        NotificationType.payment,
        'Pembayaran diterima',
        'Dana ditahan aman sampai pekerjaan selesai.',
        periodId,
      );
      return _b
          .booking(p.bookingId)
          .periods
          .firstWhere((e) => e.id == periodId);
    }
    return _b.periods[periodId]!;
  });

  @override
  Future<BookingPeriod> confirmComplete(String periodId) => _b.run(() {
    final p = _period(periodId, seekerOnly: true);
    if (!p.status.canConfirmComplete) {
      apiFail(409, 'PERIOD_INVALID_STATE', 'Status periode sudah berubah.');
    }
    _b.settle(periodId);
    return _b.periods[periodId]!;
  });

  bool _held(PeriodStatus s) =>
      s == PeriodStatus.paid ||
      s == PeriodStatus.inProgress ||
      s == PeriodStatus.awaitingConfirmation;

  /// Aturan mock: asisten berhak 20% dari dana yang sudah dibayar; sisanya refund pencari.
  RefundPreview _preview(Booking b) {
    final held = b.periods.where((p) => _held(p.status)).toList();
    final paid = held.fold<int>(0, (s, p) => s + p.total);
    final entitlement = held.fold<int>(0, (s, p) => s + p.amount * 20 ~/ 100);
    return RefundPreview(
      assistantEntitlement: entitlement,
      fee: entitlement * 10 ~/ 100,
      refundToSeeker: paid - entitlement,
    );
  }

  @override
  Future<RefundPreview> cancelPreview(String bookingId) => _b.run(() {
    final b = _b.booking(bookingId);
    if (!b.status.canCancel) {
      apiFail(
        409,
        'BOOKING_INVALID_STATE',
        'Kontrak tidak dapat dibatalkan pada status ini.',
      );
    }
    return _preview(b);
  });

  @override
  Future<Booking> cancel(String bookingId, {required String reason}) =>
      _b.run(() {
        final b = _b.booking(bookingId);
        if (!b.status.canCancel) {
          apiFail(
            409,
            'BOOKING_INVALID_STATE',
            'Kontrak tidak dapat dibatalkan pada status ini.',
          );
        }
        if (reason.trim().isEmpty) {
          apiFail(422, 'VALIDATION_FAILED', 'Alasan wajib diisi.', {
            'reason': ['Alasan wajib diisi'],
          });
        }
        final pv = _preview(b);
        for (final p in b.periods) {
          if (_held(p.status)) {
            _b.periods[p.id] = p.copyWith(status: PeriodStatus.refunded);
          } else if (p.status == PeriodStatus.awaitingPayment ||
              p.status == PeriodStatus.expired) {
            _b.periods[p.id] = p.copyWith(status: PeriodStatus.cancelled);
          }
        }
        final net = pv.assistantEntitlement - pv.fee;
        if (net > 0) {
          final aid = b.assistant.id;
          _b.balances[aid] = (_b.balances[aid] ?? 0) + net;
          (_b.walletTx[aid] ??= []).insert(
            0,
            WalletTx(
              id: _b.newId(),
              type: WalletTxType.earning,
              amount: net,
              title: '${b.listingTitle} - pembatalan',
              createdAt: _b.now(),
            ),
          );
        }
        final other = b.seeker.id == _b.me.id ? b.assistant.id : b.seeker.id;
        _b.notify(
          other,
          NotificationType.booking,
          'Kontrak dibatalkan',
          b.listingTitle,
          b.id,
        );
        _b.bookings[bookingId] = _b.bookings[bookingId]!.copyWith(
          status: BookingStatus.cancelled,
          clearPausedUntil: true,
        );
        return _b.bookingFor(
          _b.booking(bookingId),
          asAssistant: b.assistant.id == _b.me.id,
        );
      });
}
