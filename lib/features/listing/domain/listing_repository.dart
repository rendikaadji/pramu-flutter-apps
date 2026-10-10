import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';

abstract interface class ListingRepository {
  /// Lowongan `open` untuk asisten (infinite scroll via cursor).
  Future<Paged<Listing>> browse(ListingFilter filter, {String? cursor});

  /// Lowongan milik pencari (semua status).
  Future<List<Listing>> mine();

  /// Juga dipakai sebagai cek status setelah bayar (sumber kebenaran = server).
  Future<Listing> get(String id);

  /// Buat (id null) atau perbarui draf. 422 `fields` bila tidak valid.
  Future<Listing> saveDraft(ListingInput input, {String? id});

  /// Membuat tagihan fee lowongan; status jadi `awaiting_payment`.
  Future<Invoice> pay(String id, {required String idempotencyKey});

  Future<Listing> close(String id);
}
