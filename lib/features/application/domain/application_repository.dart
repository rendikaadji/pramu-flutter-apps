import 'package:pramu_apps/features/application/domain/application.dart';

abstract interface class ApplicationRepository {
  /// Asisten melamar. 409 bila sudah ada lamaran aktif; 403 bila belum verified / SKCK kurang.
  Future<Application> apply(String listingId, ApplyInput input);

  /// Lamaran milik asisten.
  Future<List<Application>> mine();

  /// Pelamar suatu lowongan (pencari).
  Future<List<Application>> forListing(String listingId);

  Future<Application> get(String id);

  /// Hanya shortlist / reject / accept / withdraw. Wawancara & kesepakatan lewat repo masing-masing.
  Future<Application> act(
    String id,
    ApplicationAction action, {
    String? reason,
  });

  Future<void> invite({
    required String assistantId,
    required String listingId,
    String? message,
  });
  Future<List<Invitation>> invitations();
}
