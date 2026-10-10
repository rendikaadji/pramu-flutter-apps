import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/pinned_actions_bar.dart';

/// M-01 Welcome: lockup merek, satu kalimat janji, tiga nilai, CTA menempel bawah.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget value(IconData icon, String title, String body) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.accentContainer,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 20, color: t.accent),
          ),
        ),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.h3),
              const SizedBox(height: AppSpace.s4),
              Text(
                body,
                style: context.text.bodySm.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ),
      ],
    );

    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
      child: Divider(height: 1, color: t.borderSubtle),
    );

    return AppScaffold(
      bottomNavigationBar: PinnedActionsBar(
        children: [
          AppButton(
            key: K.welcomeRegister,
            label: 'Daftar',
            large: true,
            onPressed: () => context.push(Routes.register),
          ),
          const SizedBox(height: AppSpace.s4),
          AppButton(
            key: K.welcomeLogin,
            label: 'Masuk',
            large: true,
            variant: AppButtonVariant.text,
            onPressed: () => context.push(Routes.login),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Align(
              alignment: const Alignment(0, -0.35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpace.s24),
                  Row(
                    children: [
                      const ExcludeSemantics(
                        child: VerificationSeal(
                          state: SealState.verified,
                          size: SealSize.lg,
                          showLabel: false,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s12),
                      Semantics(
                        header: true,
                        child: Text('Pramu', style: context.text.display),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s24),
                  Text(
                    'Asisten rumah tangga yang sudah terverifikasi.',
                    style: context.text.h1,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    'Cari, sepakati, dan bayar lewat dana aman dalam satu aplikasi.',
                    style: context.text.body.copyWith(color: t.textMuted),
                  ),
                  const SizedBox(height: AppSpace.s32),
                  AppCard(
                    child: Column(
                      children: [
                        value(
                          LucideIcons.shieldCheck,
                          'Terverifikasi',
                          'KTP dan selfie setiap pengguna diperiksa petugas.',
                        ),
                        divider,
                        value(
                          LucideIcons.wallet,
                          'Dana aman',
                          'Uang ditahan aman dan dicairkan setelah pekerjaan selesai.',
                        ),
                        divider,
                        value(
                          LucideIcons.lock,
                          'Privasi chat',
                          'Kontak pribadi disembunyikan sampai pembayaran dilakukan.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
