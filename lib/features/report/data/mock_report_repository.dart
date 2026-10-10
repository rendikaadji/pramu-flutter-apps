import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/report/domain/report_repository.dart';

/// Laporan dengan `periodId` yang bisa disengketakan -> period & booking jadi `disputed`.
/// Status `received` -> `reviewing` pada pembacaan pertama `get`.
class MockReportRepository implements ReportRepository {
  MockReportRepository(this._b);
  final MockBackend _b;

  Report _own(String id) {
    final e = _b.reports[id];
    if (e == null || e.$1 != _b.me.id) {
      apiFail(404, 'NOT_FOUND', 'Laporan tidak ditemukan.');
    }
    return e.$2;
  }

  Report _save(Report r) {
    _b.reports[r.id] = (_b.me.id, r);
    return r;
  }

  @override
  Future<Report> submit(ReportInput i) => _b.run(() {
    _b.me;
    if (i.description.trim().length < 10) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', {
        'description': ['Jelaskan minimal 10 karakter'],
      });
    }
    if ((i.bookingId != null && !isUlid(i.bookingId)) ||
        (i.periodId != null && !isUlid(i.periodId))) {
      apiFail(422, 'VALIDATION_FAILED', 'Data tidak valid.');
    }
    final pid = i.periodId;
    if (pid != null) {
      final p =
          _b.periods[pid] ??
          apiFail(404, 'NOT_FOUND', 'Periode tidak ditemukan.');
      final b = _b.booking(p.bookingId);
      if (!p.status.canDispute) {
        apiFail(409, 'PERIOD_INVALID_STATE', 'Status periode sudah berubah.');
      }
      _b.periods[pid] = p.copyWith(status: PeriodStatus.disputed);
      _b.bookings[b.id] = _b.bookings[b.id]!.copyWith(
        status: BookingStatus.disputed,
      );
    }
    return _save(
      Report(
        id: _b.newId(),
        type: i.type,
        description: i.description.trim(),
        status: ReportStatus.received,
        createdAt: _b.now(),
        bookingId: i.bookingId,
        periodId: pid,
      ),
    );
  });

  @override
  Future<List<Report>> mine() => _b.run(
    () => [
      for (final e in _b.reports.values)
        if (e.$1 == _b.me.id) e.$2,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<Report> get(String id) => _b.run(() {
    final r = _own(id);
    return r.status == ReportStatus.received
        ? _save(r.copyWith(status: ReportStatus.reviewing))
        : r;
  });

  @override
  Future<Report> addEvidence(String id, List<String> paths) => _b.run(() {
    final r = _own(id);
    if (!r.status.canAddEvidence) {
      apiFail(409, 'REPORT_INVALID_STATE', 'Laporan sudah diputuskan.');
    }
    return r;
  });

  @override
  Future<Report> shareConversation(
    String reportId, {
    required String conversationId,
  }) => _b.run(() {
    final r = _own(reportId);
    final c = _b.conversations[conversationId];
    final uid = _b.me.id;
    if (c == null || (c.seekerId != uid && c.assistantId != uid)) {
      apiFail(404, 'NOT_FOUND', 'Percakapan tidak ditemukan.');
    }
    return _save(
      r.copyWith(
        share: ChatShareConsent(
          expiresAt: _b.now().add(const Duration(days: 7)),
        ),
      ),
    );
  });

  @override
  Future<Report> revokeShare(String reportId) => _b.run(() {
    final r = _own(reportId);
    final s = r.share;
    if (s == null) {
      apiFail(409, 'REPORT_INVALID_STATE', 'Belum ada persetujuan berbagi.');
    }
    return _save(
      r.copyWith(
        share: ChatShareConsent(expiresAt: s.expiresAt, revoked: true),
      ),
    );
  });
}
