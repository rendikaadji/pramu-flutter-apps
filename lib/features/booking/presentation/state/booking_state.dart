import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/flow_refresh.dart';

/// M-72.
final bookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(bookingRepositoryProvider).bookings();
}, retry: noRetry);

/// M-73 (sekaligus sumber ringkasan untuk layar lain).
final bookingProvider = FutureProvider.autoDispose.family<Booking, String>((
  ref,
  id,
) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(bookingRepositoryProvider).booking(id);
}, retry: noRetry);

/// M-70: kesepakatan yang sudah ada untuk lamaran ini (null = usul baru, ada = ajukan balik).
final agreementDraftProvider = FutureProvider.autoDispose
    .family<Agreement?, String>((ref, applicationId) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(bookingRepositoryProvider).byApplication(applicationId);
    }, retry: noRetry);

/// Nilai syarat untuk membandingkan antarversi.
class AgreementTerms {
  const AgreementTerms(
    this.version,
    this.rate,
    this.unit,
    this.count,
    this.start,
  );

  factory AgreementTerms.of(Agreement a) =>
      AgreementTerms(a.version, a.rate, a.unit, a.periodCount, a.startDate);

  factory AgreementTerms.fromJson(Map<String, dynamic> j) => AgreementTerms(
    j['v'] as int,
    j['r'] as int,
    PeriodUnit.from(j['u'] as String?),
    j['c'] as int,
    DateTime.parse(j['s'] as String),
  );

  final int version;
  final int rate;
  final PeriodUnit unit;
  final int count;
  final DateTime start;

  Map<String, dynamic> toJson() => {
    'v': version,
    'r': rate,
    'u': unit.name,
    'c': count,
    's': start.toIso8601String(),
  };
}

class AgreementView {
  const AgreementView(this.agreement, this.before);
  final Agreement agreement;

  /// Versi sebelumnya yang pernah dilihat pengguna (null = tidak ada pembanding).
  final AgreementTerms? before;
}

/// M-71. Pembanding versi disimpan lokal (hanya angka syarat, tanpa PII).
class AgreementNotifier extends AsyncNotifier<AgreementView> {
  AgreementNotifier(this.id);
  final String id;

  String get _key => 'agreement_seen_$id';

  @override
  Future<AgreementView> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    final a = await ref.read(bookingRepositoryProvider).agreement(id);
    return AgreementView(a, _before(a));
  }

  AgreementTerms? _before(Agreement a) {
    final prefs = ref.read(prefsProvider);
    final now = AgreementTerms.of(a);
    AgreementTerms? seen, base;
    try {
      final j =
          jsonDecode(prefs.getString(_key) ?? 'null') as Map<String, dynamic>?;
      if (j != null) {
        seen = AgreementTerms.fromJson(j['seen'] as Map<String, dynamic>);
        final b = j['base'];
        base = b == null
            ? null
            : AgreementTerms.fromJson(b as Map<String, dynamic>);
      }
    } on Object {
      seen = null;
    }
    if (seen != null && seen.version == now.version) return base;
    final next = seen != null && seen.version < now.version ? seen : null;
    unawaited(
      prefs.setString(
        _key,
        jsonEncode({'seen': now.toJson(), 'base': next?.toJson()}),
      ),
    );
    return next;
  }

  /// Setuju hanya untuk versi yang sedang ditampilkan; 409 -> layar memuat ulang.
  Future<void> approve() async {
    final cur = state.requireValue;
    final a = await ref
        .read(bookingRepositoryProvider)
        .approve(id, version: cur.agreement.version);
    // Layar ditutup selama menunggu: ref sudah dibuang, jangan menyentuh state/provider lain.
    if (!ref.mounted) return;
    state = AsyncData(AgreementView(a, cur.before));
    // Persetujuan kedua pihak membuat kontrak: daftar kontrak/beranda/lamaran harus ikut baru.
    invalidateFlow(ref.invalidate);
  }
}

final agreementProvider = AsyncNotifierProvider.autoDispose
    .family<AgreementNotifier, AgreementView, String>(
      AgreementNotifier.new,
      retry: noRetry,
    );
