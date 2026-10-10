import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:pramu_apps/features/verification/presentation/widgets/capture_step.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-14 Tinjau & kirim: pratinjau 2 foto (ketuk = zoom), NIK bertopeng 16 digit,
/// persetujuan, progres unggah. Gagal -> foto tetap ada, "Kirim lagi" tanpa foto ulang.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with ApiActionMixin {
  final _nik = TextEditingController();
  bool _consent = false;
  String? _local;
  double _progress = 0;

  @override
  void dispose() {
    _nik.dispose();
    super.dispose();
  }

  void _zoom(CapturedPhoto p) => showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.s16),
      child: Stack(
        children: [
          InteractiveViewer(child: Image.memory(p.bytes)),
          Positioned(
            top: AppSpace.s4,
            right: AppSpace.s4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ctx.tokens.surface.withValues(alpha: .85),
                shape: BoxShape.circle,
              ),
              child: AppIconButton(
                icon: LucideIcons.x,
                label: 'Tutup',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit(CaptureDraft draft) async {
    final nikErr = validateNik(_nik.text);
    setState(() => _local = nikErr);
    if (nikErr != null || !_consent) return;
    final ok = await act(() async {
      await ref
          .read(verificationRepositoryProvider)
          .submit(
            ktpPath: draft.ktp!.path,
            selfiePath: draft.selfie!.path,
            nik: _nik.text,
            onProgress: (f) {
              if (mounted) setState(() => _progress = f);
            },
          );
    }, onConflict: () => context.go(Routes.verificationStatus));
    if (!ok || !mounted) return;
    await ref.read(captureDraftProvider.notifier).discard();
    _nik.clear();
    try {
      await ref.read(sessionProvider.notifier).refreshUser();
    } on Object {
      // status ditampilkan dari API di layar status
    }
    if (mounted) context.go(Routes.verificationStatus);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(captureDraftProvider);
    final ktp = draft.ktp;
    final selfie = draft.selfie;
    if (ktp == null || selfie == null) {
      return AppScaffold(
        title: 'Tinjau dan kirim',
        body: EmptyState(
          icon: LucideIcons.camera,
          title: 'Foto belum lengkap',
          message: 'Ambil foto KTP dan selfie dulu sebelum mengirim.',
          actionLabel: 'Mulai dari awal',
          onAction: () => context.go(Routes.verificationGuide),
        ),
      );
    }
    final t = context.tokens;
    final err = actionError;
    Widget thumb(String label, CapturedPhoto p, String route) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.label),
          const SizedBox(height: AppSpace.s8),
          GestureDetector(
            onTap: () => _zoom(p),
            child: PhotoPreview(
              photo: p,
              label: 'Pratinjau $label, ketuk untuk memperbesar',
            ),
          ),
          AppButton(
            label: 'Ulangi foto',
            variant: AppButtonVariant.text,
            expand: false,
            onPressed: busy ? null : () => context.push('$route?retake=1'),
          ),
        ],
      ),
    );
    return SecureScreenGuard(
      child: AppScaffold(
        title: 'Tinjau dan kirim',
        scrollable: true,
        banner: err != null && err.isNetwork ? const OfflineBanner() : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StepProgress(current: 3, total: 3, title: 'Tinjau dan kirim'),
            const SizedBox(height: AppSpace.s16),
            if (err != null) ActionErrorBox(error: err),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thumb('Foto KTP', ktp, Routes.verificationKtp),
                const SizedBox(width: AppSpace.s12),
                thumb('Selfie dengan KTP', selfie, Routes.verificationSelfie),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            AppTextField(
              key: K.nikInput,
              label: 'Nomor KTP (NIK)',
              helper: '16 digit sesuai KTP',
              controller: _nik,
              obscure: true,
              sensitive: true,
              maxLength: 16,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: _local ?? fieldError('nik'),
            ),
            const SizedBox(height: AppSpace.s12),
            CheckboxListTile(
              key: K.verificationConsent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consent,
              onChanged: busy
                  ? null
                  : (v) => setState(() => _consent = v ?? false),
              title: Text(
                'Data ini benar dan milik saya.',
                style: context.text.body,
              ),
            ),
            if (busy) ...[
              const SizedBox(height: AppSpace.s8),
              Semantics(
                liveRegion: true,
                label: 'Mengunggah ${(_progress * 100).round()} persen',
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  color: t.primary,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.s16),
            AppButton(
              key: K.verificationSubmit,
              label: err == null ? 'Kirim verifikasi' : 'Kirim lagi',
              large: true,
              loading: busy,
              onPressed: _consent && canAct ? () => _submit(draft) : null,
            ),
          ],
        ),
      ),
    );
  }
}
