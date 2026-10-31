import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';

class Paket {
  const Paket({
    required this.id,
    required this.nama,
    required this.durasiBulan,
    required this.harga,
    required this.batasJobAktif,
  });

  factory Paket.fromJson(Json j) => Paket(
    id: j['id'] as String,
    nama: j['nama'] as String? ?? '',
    durasiBulan: (j['durasi_bulan'] as num?)?.toInt() ?? 0,
    harga: Uang.fromJson(j['harga']),
    batasJobAktif: (j['batas_job_aktif'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String nama;
  final int durasiBulan;
  final Uang harga;
  final int batasJobAktif;
}

/// Harga prorata untuk satu paket yang bisa dipilih sekarang (`upgrade` di `GET /langganan`).
class OpsiUpgrade {
  const OpsiUpgrade({
    required this.paketId,
    required this.bayar,
    required this.boleh,
    this.alasan,
  });

  factory OpsiUpgrade.fromJson(Json j) => OpsiUpgrade(
    paketId: j['paket_id'] as String,
    bayar: Uang.fromJson(j['bayar']),
    boleh: j['boleh'] as bool? ?? false,
    alasan: j['alasan'] as String?,
  );

  final String paketId;
  final Uang bayar;
  final bool boleh;
  final String? alasan;
}

class LanggananInfo {
  const LanggananInfo({
    this.paket,
    this.status,
    this.berakhir,
    required this.jobAktif,
    required this.batasJobAktif,
    this.upgrade = const [],
  });

  factory LanggananInfo.fromJson(Json j) => LanggananInfo(
    paket: j['paket'] == null ? null : Paket.fromJson(j['paket'] as Json),
    status: j['status'] as String?,
    berakhir: j['berakhir'] == null
        ? null
        : DateTime.parse(j['berakhir'] as String),
    jobAktif: (j['job_aktif'] as num?)?.toInt() ?? 0,
    batasJobAktif: (j['batas_job_aktif'] as num?)?.toInt() ?? 0,
    upgrade: [
      for (final u in (j['upgrade'] as List? ?? const []))
        OpsiUpgrade.fromJson(u as Json),
    ],
  );

  final Paket? paket;
  final String? status;
  final DateTime? berakhir;
  final int jobAktif;
  final int batasJobAktif;
  final List<OpsiUpgrade> upgrade;

  bool get aktif => status == 'AKTIF' || status == 'TENGGANG';

  OpsiUpgrade? upgradeUntuk(String paketId) {
    for (final u in upgrade) {
      if (u.paketId == paketId) return u;
    }
    return null;
  }
}

final langgananProvider = FutureProvider.autoDispose<LanggananInfo>(
  (ref) async => LanggananInfo.fromJson(
    await ref.watch(apiClientProvider).get('/langganan') as Json,
  ),
);

final paketProvider = FutureProvider.autoDispose<List<Paket>>((ref) async {
  final data = await ref.watch(apiClientProvider).get('/paket') as List;
  return [for (final p in data) Paket.fromJson(p as Json)];
});
