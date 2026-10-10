import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/mock/mock_flows.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/domain/booking_repository.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';

/// Lawan bicara `bot` menyetujui usulan saat kesepakatan dibaca. Period bergerak otomatis (lihat MockBackend.stepDelay).
class MockBookingRepository implements BookingRepository {
  MockBookingRepository(this._b);
  final MockBackend _b;

  Application _app(String id) {
    final app = _b.applications[id];
    final uid = _b.me.id;
    if (app == null || (app.seeker.id != uid && app.assistant.id != uid)) {
      apiFail(404, 'NOT_FOUND', 'Lamaran tidak ditemukan.');
    }
    return app;
  }

  Role _roleIn(Application app) =>
      app.seeker.id == _b.me.id ? Role.seeker : Role.assistant;

  Agreement _agreement(String id) {
    final a =
        _b.agreements[id] ??
        apiFail(404, 'NOT_FOUND', 'Kesepakatan tidak ditemukan.');
    _app(a.applicationId);
    _b.reactAgreement(id);
    return _b.agreements[id]!;
  }

  void _validate(AgreementInput i) {
    final fields = <String, List<String>>{
      if (i.rate <= 0) 'rate': ['Tarif harus lebih dari 0'],
      if (i.periodCount < 1 || i.periodCount > 24)
        'period_count': ['Jumlah periode 1 sampai 24'],
      if (i.startDate.isBefore(_b.now()))
        'start_date': ['Tanggal mulai tidak boleh di masa lalu'],
    };
    if (fields.isNotEmpty) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', fields);
    }
  }

  @override
  Future<Fees> previewFees({required int rate, required int periodCount}) =>
      _b.run(() {
        if (rate <= 0 || periodCount < 1) {
          apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', {
            'rate': ['Tarif tidak valid'],
          });
        }
        return _b.feesFor(rate * periodCount);
      });

  @override
  Future<Agreement> propose(String applicationId, AgreementInput input) =>
      _b.run(() {
        final app = _app(applicationId);
        if (app.status != ApplicationStatus.accepted ||
            app.agreementId != null) {
          apiFail(
            409,
            'APPLICATION_INVALID_STATE',
            'Status lamaran sudah berubah.',
          );
        }
        _validate(input);
        final role = _roleIn(app);
        final now = _b.now();
        final a = Agreement(
          id: _b.newId(),
          applicationId: app.id,
          version: 1,
          rate: input.rate,
          unit: input.unit,
          periodCount: input.periodCount,
          startDate: input.startDate,
          proposedBy: role,
          fees: _b.feesFor(input.rate * input.periodCount),
          seekerApprovedAt: role == Role.seeker ? now : null,
          assistantApprovedAt: role == Role.assistant ? now : null,
        );
        _b.agreements[a.id] = a;
        _b.applications[app.id] = app.copyWith(agreementId: a.id);
        final other = role == Role.seeker ? app.assistant.id : app.seeker.id;
        _b.notify(
          other,
          NotificationType.agreement,
          'Usulan kesepakatan',
          app.listingTitle,
          a.id,
        );
        return a;
      });

  @override
  Future<Agreement> agreement(String id) => _b.run(() => _agreement(id));

  @override
  Future<Agreement?> byApplication(String applicationId) => _b.run(() {
    final id = _app(applicationId).agreementId;
    return id == null ? null : _agreement(id);
  });

  @override
  Future<Agreement> approve(String id, {required int version}) => _b.run(() {
    final a = _agreement(id);
    final role = _roleIn(_app(a.applicationId));
    if (version != a.version) {
      apiFail(
        409,
        'AGREEMENT_VERSION_STALE',
        'Kesepakatan sudah diperbarui. Muat ulang.',
      );
    }
    if (!a.canApprove(role)) {
      apiFail(
        409,
        'AGREEMENT_INVALID_STATE',
        'Status kesepakatan sudah berubah.',
      );
    }
    return _b.approveAgreement(a, role);
  });

  @override
  Future<Agreement> counter(String id, AgreementInput input) => _b.run(() {
    final a = _agreement(id);
    final app = _app(a.applicationId);
    final role = _roleIn(app);
    if (!a.canCounter(role)) {
      apiFail(
        409,
        'AGREEMENT_INVALID_STATE',
        'Status kesepakatan sudah berubah.',
      );
    }
    _validate(input);
    final now = _b.now();
    final next = a.copyWith(
      version: a.version + 1,
      rate: input.rate,
      unit: input.unit,
      periodCount: input.periodCount,
      startDate: input.startDate,
      proposedBy: role,
      fees: _b.feesFor(input.rate * input.periodCount),
      clearApprovals: true,
    );
    final proposed = role == Role.seeker
        ? next.copyWith(seekerApprovedAt: now)
        : next.copyWith(assistantApprovedAt: now);
    _b.agreements[id] = proposed;
    final other = role == Role.seeker ? app.assistant.id : app.seeker.id;
    _b.notify(
      other,
      NotificationType.agreement,
      'Kesepakatan diajukan balik',
      app.listingTitle,
      id,
    );
    return proposed;
  });

  @override
  Future<List<Booking>> bookings() => _b.run(() {
    final uid = _b.me.id;
    return [
      for (final b in _b.bookings.values.toList())
        if (b.seeker.id == uid || b.assistant.id == uid) _b.booking(b.id),
    ]..sort((a, b) => b.startDate.compareTo(a.startDate));
  });

  @override
  Future<Booking> booking(String id) => _b.run(() => _b.booking(id));

  @override
  Future<BookingPeriod> period(String id) => _b.run(() {
    final p =
        _b.periods[id] ?? apiFail(404, 'NOT_FOUND', 'Periode tidak ditemukan.');
    _b.booking(p.bookingId);
    return _b.periods[id]!;
  });
}
