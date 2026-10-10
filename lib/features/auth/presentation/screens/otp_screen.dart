import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/data/auth_providers.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/presentation/state/pending_otp.dart';
import 'package:pramu_apps/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _otpValidSeconds = 5 * 60;
// ponytail: server tidak mengirim Retry-After; pesan server menyebut 60 menit.
const _lockSeconds = 60 * 60;

/// M-03 OTP: 6 digit, hitung mundur 5 menit, kirim ulang, 429 -> terkunci + hitung mundur.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with ApiActionMixin {
  String _code = '';
  String? _otpError;
  int _round = 0;
  bool _locked = false;

  Future<void> _verify(String phone) async {
    if (_code.length != 6) return;
    setState(() => _otpError = null);
    late final AuthSession session;
    final ok = await act(() async {
      session = await ref
          .read(authRepositoryProvider)
          .verifyOtp(phone: phone, code: _code);
    });
    if (!mounted) return;
    if (ok) {
      ref.read(pendingOtpProvider.notifier).set(null);
      await ref.read(sessionProvider.notifier).signIn(session);
      return;
    }
    final err = actionError;
    setState(() {
      if (err != null && err.isRateLimited) {
        _locked = true;
      } else if (err != null && err.isValidation) {
        _otpError = fieldError('code') ?? err.message;
      }
    });
  }

  Future<void> _resend(String phone) async {
    final ok = await act(() => ref.read(authRepositoryProvider).sendOtp(phone));
    if (ok && mounted) {
      setState(() {
        _round++;
        _otpError = null;
      });
      AppSnack.show(context, 'Kode baru sudah dikirim', success: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(pendingOtpProvider);
    if (phone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.register);
      });
      return const AppScaffold(title: 'Verifikasi OTP', body: SizedBox());
    }
    final t = context.tokens;
    return AppScaffold(
      title: 'Verifikasi nomor HP',
      scrollable: true,
      banner: offlineBannerFor(actionError),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepProgress(current: 2, total: 2, title: 'Verifikasi nomor'),
          const SizedBox(height: AppSpace.s24),
          Text(
            'Masukkan 6 digit kode yang kami kirim ke ${maskPhone(phone)}.',
            style: context.text.body,
          ),
          const SizedBox(height: AppSpace.s24),
          OtpInput(
            key: K.otpInput,
            enabled: !_locked && !busy,
            errorText: _otpError,
            onChanged: (v) => setState(() => _code = v),
            onCompleted: (_) => _verify(phone),
          ),
          const SizedBox(height: AppSpace.s16),
          if (_locked)
            AppCard(
              color: t.dangerContainer,
              borderColor: t.danger.withValues(alpha: .4),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.timer, color: t.danger),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: CountdownBuilder(
                        seconds: _lockSeconds,
                        builder: (_, left) => Text(
                          'Terlalu banyak percobaan. Coba lagi dalam '
                          '${formatCountdown(left)}.',
                          style: context.text.body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (actionError != null && _otpError == null)
            ActionErrorBox(error: actionError!),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.otpSubmit,
            label: 'Verifikasi',
            large: true,
            loading: busy,
            onPressed: !_locked && _code.length == 6 && canAct
                ? () => _verify(phone)
                : null,
          ),
          const SizedBox(height: AppSpace.s16),
          CountdownBuilder(
            key: ValueKey('otp-$_round'),
            seconds: _otpValidSeconds,
            builder: (_, left) => Column(
              children: [
                Semantics(
                  liveRegion: left == 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          LucideIcons.timer,
                          size: 16,
                          color: t.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Flexible(
                        child: Text(
                          left > 0
                              ? 'Kode berlaku ${formatCountdown(left)}'
                              : 'Kode kedaluwarsa. Kirim ulang kode.',
                          style: context.text.bodySm.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppButton(
                      key: K.otpChangePhone,
                      label: 'Ubah nomor',
                      variant: AppButtonVariant.text,
                      expand: false,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.register),
                    ),
                    AppButton(
                      key: K.otpResend,
                      label: 'Kirim ulang kode',
                      variant: AppButtonVariant.text,
                      expand: false,
                      onPressed: left == 0 && canAct && !_locked
                          ? () => _resend(phone)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
