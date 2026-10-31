import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';

/// Tagihan dari `GET /tagihan`; `qrPayload` ada selama MENUNGGU.
class Tagihan {
  const Tagihan({
    required this.id,
    required this.judul,
    required this.nominal,
    required this.status,
    this.nominalJikaTerlambat,
    this.qrPayload,
    this.berlakuSampai,
    this.referensi,
  });

  factory Tagihan.fromJson(Json j) => Tagihan(
    id: j['id'] as String,
    judul: j['judul'] as String? ?? '',
    nominal: Uang.fromJson(j['nominal']),
    status: j['status'] as String? ?? 'MENUNGGU',
    nominalJikaTerlambat: j['nominal_jika_terlambat'] == null
        ? null
        : Uang.fromJson(j['nominal_jika_terlambat']),
    qrPayload: j['qr_payload'] as String?,
    berlakuSampai: BatasWaktu.fromJson(j['berlaku_sampai']),
    referensi: j['referensi'] as String?,
  );

  final String id;
  final String judul;
  final Uang nominal;
  final String status;
  final Uang? nominalJikaTerlambat;
  final String? qrPayload;
  final BatasWaktu? berlakuSampai;
  final String? referensi;

  bool get menunggu => status == 'MENUNGGU';
}

final tagihanDaftarProvider = FutureProvider.autoDispose<Paged<Tagihan>>(
  (ref) => ref.watch(apiClientProvider).getPage('/tagihan', Tagihan.fromJson),
);

final tagihanProvider = FutureProvider.autoDispose.family<Tagihan, String>(
  (ref, id) async => Tagihan.fromJson(
    await ref.watch(apiClientProvider).get('/tagihan/$id') as Json,
  ),
);
