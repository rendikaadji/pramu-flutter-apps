import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-01 Welcome.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget point(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, color: t.accent)),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.h3),
                Text(body, style: context.text.body),
              ],
            ),
          ),
        ],
      ),
    );
    return AppScaffold(
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpace.s48),
          Semantics(
            header: true,
            child: Text('Pramu', style: context.text.display),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Cari asisten rumah tangga yang sudah terverifikasi. '
            'Dibayar lewat dana aman.',
            style: context.text.h3.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpace.s32),
          point(
            LucideIcons.shieldCheck,
            'Terverifikasi',
            'KTP dan selfie setiap pengguna diperiksa petugas.',
          ),
          point(
            LucideIcons.wallet,
            'Dana aman',
            'Uang ditahan aman dan dicairkan setelah pekerjaan selesai.',
          ),
          point(
            LucideIcons.lock,
            'Privasi chat',
            'Kontak pribadi disembunyikan sampai pembayaran dilakukan.',
          ),
          const SizedBox(height: AppSpace.s32),
          AppButton(
            key: K.welcomeRegister,
            label: 'Daftar',
            large: true,
            onPressed: () => context.push(Routes.register),
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            key: K.welcomeLogin,
            label: 'Masuk',
            large: true,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.login),
          ),
        ],
      ),
    );
  }
}
