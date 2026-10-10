import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/auth/data/auth_providers.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/auth/presentation/state/pending_otp.dart';
import 'package:pramu_apps/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-05 Masuk.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with ApiActionMixin {
  final _id = TextEditingController();
  final _password = TextEditingController();
  String? _idError;
  String? _pwError;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _id.text.trim();
    setState(() {
      _idError = validateRequired(id, 'Nomor HP atau email');
      _pwError = validateRequired(_password.text, 'Kata sandi');
    });
    if (_idError != null || _pwError != null) return;
    late final AuthSession session;
    final ok = await act(() async {
      session = await ref
          .read(authRepositoryProvider)
          .login(identifier: id, password: _password.text);
    });
    if (ok && mounted) {
      await ref.read(sessionProvider.notifier).signIn(session);
    }
  }

  Future<void> _verifyPhone() async {
    final id = _id.text.trim();
    if (!isValidPhone(id)) return;
    final phone = normalizePhone(id);
    final ok = await act(() => ref.read(authRepositoryProvider).sendOtp(phone));
    if (ok && mounted) {
      ref.read(pendingOtpProvider.notifier).set(phone);
      context.push(Routes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final expired = ref.watch(sessionProvider.select((s) => s.expired));
    final err = actionError;
    final suspended = err?.code == 'ACCOUNT_SUSPENDED';
    final phoneUnverified = err?.code == 'PHONE_NOT_VERIFIED';
    return AppScaffold(
      title: 'Masuk',
      glow: true,
      scrollable: true,
      banner: offlineBannerFor(err),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            icon: LucideIcons.logIn,
            title: 'Selamat datang kembali',
            subtitle: 'Lanjutkan mencari asisten atau pekerjaan Anda.',
          ),
          if (expired)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s16),
              child: AppCard(
                color: t.warningContainer,
                child: Text(
                  'Sesi Anda berakhir. Silakan masuk lagi.',
                  style: context.text.body,
                ),
              ),
            ),
          if (suspended)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s16),
              child: AppCard(
                color: t.dangerContainer,
                borderColor: t.danger.withValues(alpha: .4),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.ban, color: t.danger),
                      const SizedBox(width: AppSpace.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Akun ditangguhkan', style: context.text.h3),
                            Text(
                              '${err!.message} Anda tidak dapat masuk sampai '
                              'tim bantuan meninjau akun ini.',
                              style: context.text.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (err != null)
            ActionErrorBox(error: err),
          AppTextField(
            key: K.loginPhone,
            label: 'Nomor HP atau email',
            prefixIcon: LucideIcons.user,
            controller: _id,
            errorText: _idError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            key: K.loginPassword,
            label: 'Kata sandi',
            prefixIcon: LucideIcons.lock,
            controller: _password,
            errorText: _pwError,
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => canAct ? _submit() : null,
          ),
          if (phoneUnverified && isValidPhone(_id.text)) ...[
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: 'Verifikasi nomor HP',
              variant: AppButtonVariant.tonal,
              onPressed: canAct ? _verifyPhone : null,
            ),
          ],
          const SizedBox(height: AppSpace.s24),
          AppButton(
            key: K.loginSubmit,
            label: 'Masuk',
            large: true,
            loading: busy,
            onPressed: canAct ? _submit : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              key: K.loginForgot,
              label: 'Lupa sandi?',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: () => context.push(Routes.forgot),
            ),
          ),
          AuthSwitchRow(
            prompt: 'Belum punya akun?',
            child: AppButton(
              key: K.loginRegister,
              label: 'Daftar',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: () => context.go(Routes.register),
            ),
          ),
        ],
      ),
    );
  }
}
