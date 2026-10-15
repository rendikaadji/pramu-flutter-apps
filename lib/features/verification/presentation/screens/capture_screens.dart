import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:pramu_apps/features/verification/presentation/widgets/capture_step.dart';

/// `?retake=1`: dibuka dari layar tinjau, selesai = kembali (bukan lanjut ke langkah berikut).
bool _retake(BuildContext context) =>
    GoRouterState.of(context).uri.queryParameters['retake'] == '1';

/// M-12 Foto KTP (kamera belakang; galeri hanya bila izin kamera ditolak).
class KtpScreen extends ConsumerWidget {
  const KtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(captureDraftProvider);
    return CaptureStep(
      title: 'Foto KTP',
      step: 1,
      instruction: 'Letakkan KTP di permukaan datar, lalu foto seluruh kartu.',
      photo: draft.ktp,
      captureKey: K.ktpCapture,
      galleryWhenDenied: true,
      guideIcon: LucideIcons.idCard,
      guideLabel: 'Seluruh kartu berada di dalam bingkai',
      onPicked: ref.read(captureDraftProvider.notifier).setKtp,
      onNext: () => _retake(context)
          ? context.pop()
          : context.push(Routes.verificationSelfie),
    );
  }
}

/// M-13 Selfie + KTP (kamera depan; galeri tidak diizinkan).
class SelfieScreen extends ConsumerWidget {
  const SelfieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(captureDraftProvider);
    return CaptureStep(
      title: 'Selfie dengan KTP',
      step: 2,
      instruction:
          'Pegang KTP di samping wajah Anda. Pastikan wajah dan KTP terlihat '
          'jelas.',
      photo: draft.selfie,
      captureKey: K.selfieCapture,
      front: true,
      guideIcon: LucideIcons.scanFace,
      guideLabel: 'Wajah dan KTP berada dalam satu bingkai',
      nextLabel: 'Tinjau foto',
      onPicked: ref.read(captureDraftProvider.notifier).setSelfie,
      onNext: () => _retake(context)
          ? context.pop()
          : context.push(Routes.verificationReview),
    );
  }
}
