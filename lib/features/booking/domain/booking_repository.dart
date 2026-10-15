import 'package:pramu_apps/features/booking/domain/booking.dart';

abstract interface class BookingRepository {
  /// Estimasi fee langsung (M-70). Angka final tetap dari respons server.
  Future<Fees> previewFees({required int rate, required int periodCount});

  /// Usulan kesepakatan dari lamaran `accepted`. Pengusul otomatis setuju.
  Future<Agreement> propose(String applicationId, AgreementInput input);

  Future<Agreement> agreement(String id);

  /// Null bila belum ada kesepakatan.
  Future<Agreement?> byApplication(String applicationId);

  /// 409 `AGREEMENT_VERSION_STALE` bila [version] bukan versi terbaru. Kedua setuju -> booking dibuat.
  Future<Agreement> approve(String id, {required int version});

  /// Ajukan balik: versi naik, persetujuan direset.
  Future<Agreement> counter(String id, AgreementInput input);

  Future<List<Booking>> bookings();
  Future<Booking> booking(String id);
  Future<BookingPeriod> period(String id);
}
