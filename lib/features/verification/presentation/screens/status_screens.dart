import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/platform/secure_screen.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';
import 'package:pramu_apps/features/verification/data/verification_providers.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:pramu_apps/features/verification/presentation/widgets/capture_step.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

SealState _seal(VerificationStatus s) => switch (s) {
  VerificationStatus.verified => SealState.verified,
  VerificationStatus.rejected => SealState.rejected,
  _ => SealState.pending,
};

void _toHome(BuildContext context, WidgetRef ref) {
  final role = ref.read(sessionProvider).activeRole;
  context.go(role == null ? Routes.pickRole : Routes.home(role));
}

/// Isi status bersama M-15 / M-16: segel + teks + alasan penolakan + aksi.
class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.v,
    required this.pendingText,
    required this.verifiedText,
    this.extra = const [],
  });

  final Verification v;
  final String pendingText;
  final String verifiedText;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = v.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s != VerificationStatus.rejected)
          Center(
            child: s.isVerified
                ? const SuccessIllustration(size: 200)
                : const VerifyIllustration(size: 200),
          ),
        Semantics(
          liveRegion: true,
          container: true,
          child: Center(
            child: VerificationSeal(
              state: _seal(s),
              size: SealSize.lg,
              stamp: s.isVerified,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        if (s == VerificationStatus.pending)
          Text(
            pendingText,
            style: context.text.body.copyWith(color: t.textMuted),
            textAlign: TextAlign.center,
          )
        else if (s.isVerified)
          Text(
            verifiedText,
            style: context.text.body.copyWith(color: t.textMuted),
            textAlign: TextAlign.center,
          )
        else if (s == VerificationStatus.rejected)
          AppCard(
            color: t.dangerContainer,
            borderColor: t.danger.withValues(alpha: .4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(LucideIcons.circleAlert, color: t.danger),
                    ),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: Text(
                        'Verifikasi belum berhasil',
                        style: context.text.h3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  v.rejectReason ?? 'Berkas belum memenuhi syarat.',
                  style: context.text.body,
                ),
                const SizedBox(height: AppSpace.s12),
                Text(
                  'Tips: foto di tempat terang, seluruh kartu terlihat, tanpa '
                  'pantulan. Bila terus gagal, hubungi bantuan.',
                  style: context.text.bodySm,
                ),
              ],
            ),
          )
        else
          Text('Belum ada berkas yang dikirim.', style: context.text.body),
        const SizedBox(height: AppSpace.s16),
        ...extra,
      ],
    );
  }
}

/// Memuat provider status dengan pola skeleton / error / data.
Widget _async(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<Verification> value,
  VoidCallback retry,
  Widget Function(Verification) data,
) => AsyncBody<Verification>(
  value: value,
  onRetry: retry,
  skeleton: Column(
    children: const [
      SizedBox(height: AppSpace.s32),
      AppSkeleton.box(48, radius: 24),
      SizedBox(height: AppSpace.s16),
      AppSkeleton.line(),
    ],
  ),
  data: (_, v) => data(v),
);

/// M-15 Status verifikasi KTP + selfie. Memeriksa ulang tiap 15 detik selagi `pending`.
class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (ref.read(verificationProvider).value?.status ==
          VerificationStatus.pending) {
        ref.invalidate(verificationProvider);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationProvider, (_, next) {
      final s = next.value?.status;
      if (s != null &&
          s != VerificationStatus.none &&
          s != ref.read(sessionProvider).user?.verification) {
        ref.read(sessionProvider.notifier).refreshUser().ignore();
      }
    });
    final value = ref.watch(verificationProvider);
    return AppScaffold(
      title: 'Status verifikasi',
      glow: true,
      banner: value.hasError && value.hasValue ? const OfflineBanner() : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(verificationProvider.future),
        child: _async(
          context,
          ref,
          value,
          () => ref.invalidate(verificationProvider),
          (v) => SingleChildScrollView(
            key: K.verificationStatus,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
            child: _StatusBody(
              v: v,
              pendingText:
                  'Berkas Anda sedang diperiksa. Biasanya selesai dalam 1x24 '
                  'jam. Kami kabari lewat notifikasi.',
              verifiedText: 'Akun Anda sudah terverifikasi. Selamat!',
              extra: [
                if (v.status.canUpload) ...[
                  AppButton(
                    label: v.status == VerificationStatus.rejected
                        ? 'Unggah ulang'
                        : 'Unggah sekarang',
                    large: true,
                    onPressed: () => context.push(Routes.verificationGuide),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
                if (v.status == VerificationStatus.pending) ...[
                  AppButton(
                    label: 'Periksa status',
                    icon: LucideIcons.refreshCw,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ref.invalidate(verificationProvider),
                  ),
                  const SizedBox(height: AppSpace.s8),
                ],
                AppButton(
                  label: 'Ke beranda',
                  variant: v.status.isVerified
                      ? AppButtonVariant.primary
                      : AppButtonVariant.text,
                  onPressed: () => _toHome(context, ref),
                ),
                const SizedBox(height: AppSpace.s16),
                const PrivacyNote(
                  'Hanya petugas verifikasi yang dapat membuka berkas ini, '
                  'dan setiap akses tercatat.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// M-16 SKCK: kamera atau galeri (<= 5 MB, tanpa EXIF), status, dipakai ulang antar lamaran.
class SkckScreen extends ConsumerStatefulWidget {
  const SkckScreen({super.key, this.listingId});

  /// Lowongan yang memintanya (opsional, ULID tervalidasi).
  final String? listingId;

  @override
  ConsumerState<SkckScreen> createState() => _SkckScreenState();
}

class _SkckScreenState extends ConsumerState<SkckScreen> with ApiActionMixin {
  CapturedPhoto? _photo;
  String? _photoError;
  bool _denied = false;
  bool _picking = false;
  late final PhotoService _service = ref.read(photoServiceProvider);

  @override
  void dispose() {
    unawaited(_service.delete(_photo));
    super.dispose();
  }

  Future<void> _pick(PhotoSource source) async {
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final p = await _service.capture(source);
      if (p != null) {
        await _service.delete(_photo);
        _photo = p;
        _denied = false;
      }
    } on PhotoException catch (e) {
      _denied = e.permissionDenied;
      _photoError = e.permissionDenied ? null : e.message;
    }
    if (mounted) setState(() => _picking = false);
  }

  Future<void> _upload() async {
    final p = _photo!;
    final ok = await act(
      () => ref.read(verificationRepositoryProvider).uploadSkck(p.path),
      onConflict: () => ref.invalidate(skckProvider),
    );
    if (!ok || !mounted) return;
    await _service.delete(p);
    setState(() => _photo = null);
    ref.invalidate(skckProvider);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(skckProvider);
    final err = actionError;
    final listing = isUlid(widget.listingId) ? widget.listingId : null;
    return SecureScreenGuard(
      child: AppScaffold(
        title: 'SKCK',
        glow: true,
        banner: err != null && err.isNetwork ? const OfflineBanner() : null,
        body: RefreshIndicator(
          onRefresh: () async => ref.refresh(skckProvider.future),
          child: _async(
            context,
            ref,
            value,
            () => ref.invalidate(skckProvider),
            (v) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listing != null && !v.status.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpace.s16),
                      child: PrivacyNote(
                        'Lowongan ini mewajibkan SKCK. Unggah SKCK Anda sekali, '
                        'bisa dipakai untuk lamaran lain.',
                      ),
                    ),
                  if (err != null) ActionErrorBox(error: err),
                  _StatusBody(
                    v: v,
                    pendingText: 'SKCK Anda sedang diperiksa. Kami kabari lewat notifikasi.',
                    verifiedText: 'SKCK terverifikasi dan dapat dipakai untuk lamaran lain.',
                    extra: [
                      if (v.status.isVerified && listing != null)
                        AppButton(
                          label: 'Kembali ke lowongan',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(Routes.listingDetail(listing)),
                        ),
                      if (v.status.canUpload) ..._uploader(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _uploader(BuildContext context) {
    final p = _photo;
    return [
      if (p != null) ...[
        PhotoPreview(photo: p, label: 'Pratinjau SKCK'),
        const SizedBox(height: AppSpace.s12),
        AppButton(
          key: K.skckUpload,
          label: 'Unggah SKCK',
          large: true,
          loading: busy,
          onPressed: canAct ? _upload : null,
        ),
        const SizedBox(height: AppSpace.s12),
      ],
      if (_denied)
        PermissionRationaleCard(
          icon: LucideIcons.cameraOff,
          title: 'Izin kamera dimatikan',
          message: 'Aktifkan di Pengaturan, atau pilih foto dari galeri.',
          primaryLabel: 'Buka Pengaturan',
          onPrimary: () => openAppSettings(ref),
          secondaryLabel: 'Pilih dari galeri',
          onSecondary: () => _pick(PhotoSource.gallery),
          denied: true,
        )
      else ...[
        AppButton(
          label: p == null ? 'Foto dengan kamera' : 'Ulangi foto',
          icon: LucideIcons.camera,
          variant: AppButtonVariant.secondary,
          loading: _picking,
          onPressed: () => _pick(PhotoSource.camera),
        ),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          key: K.verificationGallery,
          label: 'Pilih dari galeri',
          icon: LucideIcons.image,
          variant: AppButtonVariant.secondary,
          onPressed: _picking ? null : () => _pick(PhotoSource.gallery),
        ),
      ],
      if (_photoError != null) ...[
        const SizedBox(height: AppSpace.s12),
        FieldErrorText(_photoError!),
      ],
    ];
  }
}
