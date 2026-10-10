import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/auth/data/auth_providers.dart';
import 'package:pramu_apps/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-06 Lupa & reset sandi: 1) HP/email 2) kode 3) sandi baru.
class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen>
    with ApiActionMixin {
  final _id = TextEditingController();
  final _password = TextEditingController();
  int _step = 0;
  String _code = '';
  String? _localError;
  String? _codeError;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _identifier {
    final v = _id.text.trim();
    return isValidPhone(v) ? normalizePhone(v) : v;
  }

  Future<void> _send() async {
    final v = _id.text.trim();
    final bad = isValidPhone(v) || validateEmail(v) == null
        ? null
        : 'Masukkan nomor HP atau email yang valid';
    setState(() => _localError = bad);
    if (bad != null) return;
    if (await act(
          () => ref
              .read(authRepositoryProvider)
              .requestPasswordReset(_identifier),
        ) &&
        mounted) {
      setState(() => _step = 1);
    }
  }

  Future<void> _save() async {
    final bad = validatePassword(_password.text);
    setState(() => _localError = bad);
    if (bad != null) return;
    final ok = await act(
      () => ref
          .read(authRepositoryProvider)
          .resetPassword(
            identifier: _identifier,
            code: _code,
            newPassword: _password.text,
          ),
    );
    if (!mounted) return;
    if (ok) {
      AppSnack.show(
        context,
        'Kata sandi diperbarui. Silakan masuk.',
        success: true,
      );
      context.go(Routes.login);
    } else if (actionError?.fields['code'] != null) {
      setState(() {
        _step = 1;
        _codeError = fieldError('code');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Nomor HP atau email', 'Kode verifikasi', 'Sandi baru'];
    return AppScaffold(
      title: 'Lupa sandi',
      scrollable: true,
      banner: offlineBannerFor(actionError),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepProgress(current: _step + 1, total: 3, title: titles[_step]),
          const SizedBox(height: AppSpace.s24),
          if (actionError != null && _codeError == null)
            ActionErrorBox(error: actionError!),
          if (_step == 0) ...[
            Text(
              'Kami kirim kode ke nomor HP atau email yang terdaftar.',
              style: context.text.body,
            ),
            const SizedBox(height: AppSpace.s16),
            AppTextField(
              key: K.forgotIdentifier,
              label: 'Nomor HP atau email',
              controller: _id,
              errorText: _localError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpace.s24),
            AppButton(
              key: K.forgotSend,
              label: 'Kirim kode',
              large: true,
              loading: busy,
              onPressed: canAct ? _send : null,
            ),
          ] else if (_step == 1) ...[
            Text(
              'Masukkan 6 digit kode yang kami kirim.',
              style: context.text.body,
            ),
            const SizedBox(height: AppSpace.s16),
            OtpInput(
              key: K.forgotCode,
              errorText: _codeError,
              onCompleted: (v) => setState(() {
                _code = v;
                _codeError = null;
                actionError = null;
                _step = 2;
              }),
            ),
          ] else ...[
            AppTextField(
              key: K.forgotNewPassword,
              label: 'Kata sandi baru',
              controller: _password,
              errorText: _localError ?? fieldError('password'),
              helper: 'Minimal 8 karakter',
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: AppSpace.s24),
            AppButton(
              key: K.forgotSave,
              label: 'Simpan',
              large: true,
              loading: busy,
              onPressed: canAct ? _save : null,
            ),
          ],
        ],
      ),
    );
  }
}
