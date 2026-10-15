import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/platform/secure_screen.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';
import 'package:url_launcher/url_launcher.dart';

/// Buka pengaturan app: channel native Android; iOS lewat `app-settings:`.
Future<void> openAppSettings(WidgetRef ref) async {
  if (await PlatformBridge.openAppSettings()) return;
  await ref.read(urlLauncherProvider)(
    Uri.parse('app-settings:'),
    LaunchMode.externalApplication,
  );
}

/// Pratinjau foto dari memori dengan watermark halus "Hanya untuk verifikasi".
class PhotoPreview extends StatelessWidget {
  const PhotoPreview({super.key, required this.photo, required this.label});
  final CapturedPhoto photo;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: t.sunken),
              Image.memory(
                photo.bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
              Positioned(
                left: AppSpace.s8,
                right: AppSpace.s8,
                bottom: AppSpace.s8,
                child: ExcludeSemantics(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.scrim.withValues(alpha: .5),
                          borderRadius: AppRadius.brXs,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s8,
                            vertical: AppSpace.s4,
                          ),
                          child: Text(
                            'Hanya untuk verifikasi',
                            style: context.text.caption.copyWith(
                              color: t.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu langkah ambil foto (KTP/selfie): penjelasan izin sebelum prompt OS, kartu izin
/// ditolak + Buka Pengaturan, pratinjau, Ulangi. Dibungkus layar aman (FLAG_SECURE).
class CaptureStep extends ConsumerStatefulWidget {
  const CaptureStep({
    super.key,
    required this.title,
    required this.step,
    required this.instruction,
    required this.photo,
    required this.onPicked,
    required this.onNext,
    required this.captureKey,
    this.front = false,
    this.galleryWhenDenied = false,
    this.guideIcon = LucideIcons.idCard,
    this.guideLabel = 'Seluruh kartu berada di dalam bingkai',
    this.nextLabel = 'Lanjutkan',
  });

  final String title;
  final int step;
  final String instruction;
  final CapturedPhoto? photo;
  final Future<void> Function(CapturedPhoto) onPicked;
  final VoidCallback onNext;
  final Key captureKey;
  final bool front;
  final bool galleryWhenDenied;

  /// Ikon dan keterangan bingkai petunjuk sebelum foto diambil.
  final IconData guideIcon;
  final String guideLabel;
  final String nextLabel;

  @override
  ConsumerState<CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends ConsumerState<CaptureStep> {
  bool _denied = false;
  bool _busy = false;
  String? _error;

  Future<void> _capture(PhotoSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await ref
          .read(photoServiceProvider)
          .capture(source, front: widget.front);
      if (p != null) {
        await widget.onPicked(p);
        _denied = false;
      }
    } on PhotoException catch (e) {
      _denied = e.permissionDenied;
      _error = e.permissionDenied ? null : e.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final photo = widget.photo;
    return SecureScreenGuard(
      child: AppScaffold(
        title: widget.title,
        scrollable: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepProgress(current: widget.step, total: 3, title: widget.title),
            const SizedBox(height: AppSpace.s16),
            Text(widget.instruction, style: context.text.body),
            const SizedBox(height: AppSpace.s16),
            if (photo != null) ...[
              PhotoPreview(photo: photo, label: 'Pratinjau ${widget.title}'),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                key: K.verificationNext,
                label: widget.nextLabel,
                large: true,
                onPressed: widget.onNext,
              ),
              const SizedBox(height: AppSpace.s12),
              AppButton(
                key: K.verificationRetake,
                label: 'Ulangi foto',
                icon: LucideIcons.rotateCcw,
                variant: AppButtonVariant.secondary,
                loading: _busy,
                onPressed: () => _capture(PhotoSource.camera),
              ),
            ] else if (_denied)
              PermissionRationaleCard(
                icon: LucideIcons.cameraOff,
                title: 'Izin kamera belum aktif',
                message: widget.galleryWhenDenied
                    ? 'Aktifkan di Pengaturan, atau pilih foto dari galeri.'
                    : 'Aktifkan izin kamera di Pengaturan untuk melanjutkan.',
                primaryLabel: 'Buka Pengaturan',
                onPrimary: () => openAppSettings(ref),
                secondaryLabel: widget.galleryWhenDenied
                    ? 'Pilih dari galeri'
                    : null,
                onSecondary: () => _capture(PhotoSource.gallery),
                denied: true,
              )
            else ...[
              Semantics(
                label: 'Petunjuk bingkai: ${widget.guideLabel}',
                excludeSemantics: true,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.primaryContainer.withValues(alpha: .5),
                      borderRadius: AppRadius.brCard,
                      border: Border.all(color: t.primary, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.guideIcon, size: 56, color: t.primary),
                        const SizedBox(height: AppSpace.s12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s16,
                          ),
                          child: Text(
                            widget.guideLabel,
                            style: context.text.label.copyWith(
                              color: t.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(LucideIcons.camera, color: t.primary),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Text(
                        'Kami memakai kamera untuk memotret KTP dan wajah Anda. '
                        'Foto tidak disimpan di galeri.',
                        style: context.text.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                key: widget.captureKey,
                label: 'Ambil foto',
                icon: LucideIcons.camera,
                large: true,
                loading: _busy,
                onPressed: () => _capture(PhotoSource.camera),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpace.s12),
              Semantics(liveRegion: true, child: FieldErrorText(_error!)),
            ],
            const SizedBox(height: AppSpace.s16),
            const PrivacyNote(
              'Foto ini hanya dipakai untuk verifikasi dan disimpan terenkripsi.',
            ),
          ],
        ),
      ),
    );
  }
}
