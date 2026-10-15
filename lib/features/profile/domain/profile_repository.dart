import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

abstract interface class ProfileRepository {
  /// Profil asisten milik pengguna aktif (null bila belum dibuat).
  Future<AssistantProfile?> myProfile();
  Future<AssistantProfile> saveProfile(AssistantProfile profile);

  /// Pencarian asisten (pencari). 403 bila pencari belum verified.
  Future<Paged<AssistantProfile>> search(
    AssistantFilter filter, {
    String? cursor,
  });
  Future<AssistantProfile> assistant(String userId);
}
