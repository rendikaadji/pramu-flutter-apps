import 'package:pramu_apps/features/booking/domain/booking.dart';

abstract interface class BookingRepository {
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

  /// Batalkan kontrak aktif (alasan wajib). Tanpa refund: tidak ada uang di platform.
  Future<Booking> cancel(String bookingId, {required String reason});
}
