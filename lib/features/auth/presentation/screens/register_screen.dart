import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/auth/data/auth_providers.dart';
import 'package:pramu_apps/features/auth/presentation/state/pending_otp.dart';
import 'package:pramu_apps/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-02 Daftar.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with ApiActionMixin {
  static const _keys = ['name', 'phone', 'email', 'password'];
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _focus = {for (final k in _keys) k: FocusNode()};
  bool _consent = false;
  Map<String, String> _local = {};

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  String? _err(String key) => _local[key] ?? fieldError(key);

  String get _strength {
    final p = _password.text;
    if (p.length < 8) return 'Lemah';
    final mixed = RegExp('[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);
    return mixed && p.length >= 10 ? 'Kuat' : 'Sedang';
  }

  Future<void> _submit() async {
    final errs = <String, String?>{
      'name': validateRequired(_name.text, 'Nama'),
      'phone': validatePhone(_phone.text),
      'email': validateEmail(_email.text),
      'password': validatePassword(_password.text),
      'consent': _consent ? null : 'Setujui persyaratan privasi untuk lanjut',
    };
    setState(() {
      actionError = null;
      _local = {
        for (final e in errs.entries)
          if (e.value != null) e.key: e.value!,
      };
    });
    if (_local.isNotEmpty) {
      for (final k in _keys) {
        if (_local.containsKey(k)) return _focus[k]!.requestFocus();
      }
      return;
    }
    final ok = await act(
      () => ref
          .read(authRepositoryProvider)
          .register(
            name: _name.text.trim(),
            phone: normalizePhone(_phone.text),
            email: _email.text.trim(),
            password: _password.text,
          ),
    );
    if (!mounted) return;
    if (ok) {
      ref.read(pendingOtpProvider.notifier).set(normalizePhone(_phone.text));
      context.push(Routes.otp);
    } else {
      for (final k in _keys) {
        if (fieldError(k) != null) return _focus[k]!.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Daftar',
      glow: true,
      scrollable: true,
      banner: offlineBannerFor(actionError),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            icon: LucideIcons.userPlus,
            title: 'Buat akun Pramu',
            subtitle: 'Cukup beberapa data. Verifikasi identitas menyusul.',
          ),
          const StepProgress(current: 1, total: 2, title: 'Data akun'),
          const SizedBox(height: AppSpace.s24),
          if (actionError != null) ActionErrorBox(error: actionError!),
          AppTextField(
            key: K.registerName,
            label: 'Nama lengkap',
            prefixIcon: LucideIcons.user,
            controller: _name,
            focusNode: _focus['name'],
            errorText: _err('name'),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            key: K.registerPhone,
            label: 'Nomor HP',
            prefixIcon: LucideIcons.phone,
            hint: '08xx atau +62xx',
            controller: _phone,
            focusNode: _focus['phone'],
            errorText: _err('phone'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            key: K.registerEmail,
            label: 'Email',
            prefixIcon: LucideIcons.mail,
            controller: _email,
            focusNode: _focus['email'],
            errorText: _err('email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            key: K.registerPassword,
            label: 'Kata sandi',
            prefixIcon: LucideIcons.lock,
            controller: _password,
            focusNode: _focus['password'],
            errorText: _err('password'),
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
            helper: _password.text.isEmpty
                ? 'Minimal 8 karakter'
                : 'Kekuatan sandi: $_strength',
          ),
          const SizedBox(height: AppSpace.s16),
          CheckboxListTile(
            key: K.registerConsent,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consent,
            onChanged: busy
                ? null
                : (v) => setState(() {
                    _consent = v ?? false;
                    _local.remove('consent');
                  }),
            title: Text(
              'Saya menyetujui pemrosesan data pribadi saya sesuai UU '
              'Pelindungan Data Pribadi.',
              style: context.text.body,
            ),
          ),
          if (_local['consent'] != null) FieldErrorText(_local['consent']!),
          const SizedBox(height: AppSpace.s24),
          AppButton(
            key: K.registerSubmit,
            label: 'Daftar',
            large: true,
            loading: busy,
            onPressed: canAct ? _submit : null,
          ),
          const SizedBox(height: AppSpace.s12),
          AuthSwitchRow(
            prompt: 'Sudah punya akun?',
            child: AppButton(
              label: 'Masuk',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: () => context.go(Routes.login),
            ),
          ),
        ],
      ),
    );
  }
}
