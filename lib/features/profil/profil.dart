import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';

/// Profil pihak lain sesuai tahap visibilitas (PRD §13): bidang di luar tahap itu null dan disebut di `terkunci`.
class ProfilPublik {
  const ProfilPublik({
    required this.ringkasan,
    this.keahlian,
    this.videoUrl,
    this.terkunci = const [],
  });

  factory ProfilPublik.fromJson(Json j) => ProfilPublik(
    ringkasan: RingkasanProfil.fromJson(j),
    keahlian: j['keahlian'] as String?,
    videoUrl: j['video_url'] as String?,
    terkunci: [for (final k in j['terkunci'] as List? ?? const []) k as String],
  );

  final RingkasanProfil ringkasan;
  final String? keahlian;
  final String? videoUrl;
  final List<String> terkunci;
}

class UlasanProfil {
  const UlasanProfil({required this.bintang, this.catatan});

  factory UlasanProfil.fromJson(Json j) => UlasanProfil(
    bintang: (j['bintang'] as num?)?.toInt() ?? 0,
    catatan: j['catatan'] as String?,
  );

  final int bintang;
  final String? catatan;
}

/// `jobId` adalah konteks yang membuat profil boleh dilihat; tanpa konteks yang sah server menjawab 404.
typedef KunciProfil = ({String id, String? jobId});

final profilProvider = FutureProvider.autoDispose
    .family<ProfilPublik, KunciProfil>(
      (ref, k) async => ProfilPublik.fromJson(
        await ref
                .watch(apiClientProvider)
                .get(
                  '/profil/${k.id}',
                  query: {if (k.jobId != null) 'job_id': k.jobId},
                )
            as Json,
      ),
    );

final ulasanProfilProvider = FutureProvider.autoDispose
    .family<Paged<UlasanProfil>, String>(
      (ref, id) => ref
          .watch(apiClientProvider)
          .getPage('/profil/$id/ulasan', UlasanProfil.fromJson),
    );
