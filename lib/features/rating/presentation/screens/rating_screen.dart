import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/rating/presentation/state/rating_state.dart';
import 'package:pramu_apps/features/rating/presentation/widgets/review_tile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _info =
    'Ulasan Anda terlihat setelah kedua pihak mengirim, atau setelah 7 hari.';

/// M-90 Beri rating.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _busy = false;
  String? _starsError;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _starsError = 'Pilih jumlah bintang, 1 sampai 5.');
      return;
    }
    final ok = await ConfirmDialog.show(
      context,
      title: 'Kirim ulasan?',
      message: 'Ulasan tidak bisa diubah setelah dikirim.',
      confirmLabel: 'Kirim ulasan',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _starsError = null;
    });
    final n = ref.read(ratingProvider(widget.bookingId).notifier);
    try {
      await n.submit(_stars, _comment.text.trim());
      if (mounted) AppSnack.show(context, 'Ulasan terkirim.', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.isConflict) {
        await ConfirmDialog.show(
          context,
          title: 'Data baru saja berubah',
          message: e.message,
          confirmLabel: 'Muat ulang',
          cancelLabel: 'Tutup',
        );
        if (mounted) ref.invalidate(ratingProvider(widget.bookingId));
      } else if (e.isValidation) {
        setState(() => _starsError = e.fields['stars']?.first ?? e.message);
      } else {
        AppSnack.show(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(ratingProvider(widget.bookingId));
    return AppScaffold(
      title: 'Beri ulasan',
      glow: true,
      scrollable: true,
      body: view.when(
        loading: () => Semantics(
          label: 'Memuat',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton.line(width: 160),
              SizedBox(height: AppSpace.s12),
              AppSkeleton.box(120),
            ],
          ),
        ),
        error: (e, _) => ApiErrorView(
          error: asApiException(e),
          onRetry: () => ref.invalidate(ratingProvider(widget.bookingId)),
        ),
        data: (v) {
          final me = ref.watch(sessionProvider.select((s) => s.user?.id));
          final other = v.booking.seeker.id == me
              ? v.booking.assistant
              : v.booking.seeker;
          final r = v.reviews;
          final left = r.deadline.difference(DateTime.now().toUtc());
          final days = (left.inHours / 24).ceil();
          final theirs = r.theirs == null
              ? null
              : ReviewTile(r.theirs!, heading: 'Ulasan dari ${other.name}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(other.name, style: context.text.h2),
              Text(
                v.booking.listingTitle,
                style: context.text.body.copyWith(
                  color: context.tokens.textMuted,
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              if (r.mine != null) ...[
                const Center(child: SuccessIllustration(size: 160)),
                const SizedBox(height: AppSpace.s8),
                Center(
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      'Terima kasih atas ulasan Anda',
                      style: context.text.h2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                ReviewTile(r.mine!, heading: 'Ulasan Anda'),
                const SizedBox(height: AppSpace.s12),
                theirs ??
                    const PrivacyNote(
                      'Ulasan dari pihak lain baru terlihat setelah ia mengirim, atau setelah 7 hari.',
                    ),
                const SizedBox(height: AppSpace.s24),
                AppButton(
                  label: 'Selesai',
                  large: true,
                  onPressed: () => context.pop(),
                ),
              ] else if (!v.booking.status.canRate)
                const EmptyState(
                  compact: true,
                  title: 'Kontrak belum selesai',
                  message: 'Ulasan dibuka setelah kontrak selesai.',
                )
              else if (left.isNegative) ...[
                const StatusChip(
                  label: 'Batas waktu 7 hari lewat',
                  tone: StatusTone.neutral,
                ),
                const SizedBox(height: AppSpace.s12),
                const Text('Ulasan bintang 5 diberikan otomatis.'),
                if (theirs != null) ...[
                  const SizedBox(height: AppSpace.s12),
                  theirs,
                ],
              ] else ...[
                StatusChip(
                  label: 'Sisa waktu: $days hari dari 7',
                  tone: StatusTone.warning,
                  icon: LucideIcons.clock,
                ),
                const SizedBox(height: AppSpace.s16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Bagaimana pengalaman Anda?',
                          style: context.text.h3,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s16),
                      Center(
                        child: RatingStars(
                          key: K.ratingStars,
                          value: _stars.toDouble(),
                          size: 44,
                          onChanged: _busy
                              ? null
                              : (n) => setState(() {
                                  _stars = n;
                                  _starsError = null;
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_starsError != null) FieldErrorText(_starsError!),
                const SizedBox(height: AppSpace.s16),
                AppTextField(
                  label: 'Komentar (opsional)',
                  controller: _comment,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_busy,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: AppSpace.s8),
                const PrivacyNote(_info),
                const SizedBox(height: AppSpace.s16),
                AppButton(
                  key: K.ratingSubmit,
                  label: 'Kirim ulasan',
                  large: true,
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Batas ulasan ${formatDate(r.deadline)}.',
                  style: context.text.caption.copyWith(
                    color: context.tokens.textMuted,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
