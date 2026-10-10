import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/features/profile/domain/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._b);
  final MockBackend _b;

  @override
  Future<AssistantProfile?> myProfile() => _b.run(() => _b.profiles[_b.me.id]);

  @override
  Future<AssistantProfile> saveProfile(AssistantProfile p) => _b.run(() {
    final u = _b.me;
    if (!p.isValid) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', {
        if (p.categories.isEmpty) 'categories': ['Pilih minimal satu kategori'],
        if (p.city.isEmpty) 'city': ['Kota wajib diisi'],
      });
    }
    return _b.profiles[u.id] = AssistantProfile(
      userId: u.id,
      name: u.name,
      photoUrl: p.photoUrl,
      categories: p.categories,
      experienceYears: p.experienceYears,
      skills: p.skills,
      rate: p.rate,
      unit: p.unit,
      city: p.city,
      available: p.available,
      verified: u.verification.isVerified,
      ratingAvg: u.ratingAvg,
      ratingCount: u.ratingCount,
      completedJobs: u.completedJobs,
      bio: p.bio,
    );
  });

  @override
  Future<Paged<AssistantProfile>> search(AssistantFilter f, {String? cursor}) =>
      _b.run(() {
        _b.requireVerified();
        final q = f.query?.toLowerCase();
        final all = [
          for (final p in _b.profiles.values)
            if (p.available &&
                _b.users[p.userId]!.verification.isVerified &&
                (q == null ||
                    p.name.toLowerCase().contains(q) ||
                    p.skills.any((s) => s.toLowerCase().contains(q))) &&
                (f.category == null || p.categories.contains(f.category)) &&
                (f.city == null || p.city == f.city) &&
                (f.unit == null || p.unit == f.unit) &&
                (f.maxRate == null || p.rate <= f.maxRate!) &&
                (f.minRating == null || p.ratingAvg >= f.minRating!))
              p,
        ];
        return _b.page(all, cursor);
      });

  @override
  Future<AssistantProfile> assistant(String userId) => _b.run(
    () =>
        _b.profiles[userId] ??
        apiFail(404, 'NOT_FOUND', 'Profil tidak ditemukan.'),
  );
}
