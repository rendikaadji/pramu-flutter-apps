import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';
import 'package:pramu_apps/features/verification/data/verification_providers.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';

/// Dapat di-override di test (image_picker tidak jalan di unit test).
final photoServiceProvider = Provider<PhotoService>(
  (ref) => ImagePickerPhotoService(),
);

class CaptureDraft {
  const CaptureDraft({this.ktp, this.selfie});
  final CapturedPhoto? ktp;
  final CapturedPhoto? selfie;
}

/// Foto KTP + selfie hanya hidup selama alur verifikasi terbuka; berkas dihapus
/// saat provider dibuang (alur ditinggalkan, logout) atau `discard()` setelah unggah.
class CaptureDraftNotifier extends Notifier<CaptureDraft> {
  CapturedPhoto? _ktp;
  CapturedPhoto? _selfie;

  @override
  CaptureDraft build() {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    final service = ref.read(photoServiceProvider);
    ref.onDispose(() {
      unawaited(service.delete(_ktp));
      unawaited(service.delete(_selfie));
    });
    return const CaptureDraft();
  }

  Future<void> setKtp(CapturedPhoto p) async {
    await ref.read(photoServiceProvider).delete(_ktp);
    _ktp = p;
    state = CaptureDraft(ktp: _ktp, selfie: _selfie);
  }

  Future<void> setSelfie(CapturedPhoto p) async {
    await ref.read(photoServiceProvider).delete(_selfie);
    _selfie = p;
    state = CaptureDraft(ktp: _ktp, selfie: _selfie);
  }

  Future<void> discard() async {
    final service = ref.read(photoServiceProvider);
    final old = (_ktp, _selfie);
    _ktp = _selfie = null;
    state = const CaptureDraft();
    await service.delete(old.$1);
    await service.delete(old.$2);
  }
}

final captureDraftProvider =
    NotifierProvider.autoDispose<CaptureDraftNotifier, CaptureDraft>(
      CaptureDraftNotifier.new,
    );

final verificationProvider = FutureProvider.autoDispose<Verification>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(verificationRepositoryProvider).current();
}, retry: (_, _) => null);

final skckProvider = FutureProvider.autoDispose<Verification>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(verificationRepositoryProvider).skck();
}, retry: (_, _) => null);
