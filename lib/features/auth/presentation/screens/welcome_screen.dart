import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/pinned_actions_bar.dart';

/// M-01 Welcome: wordmark, carousel tiga nilai produk berilustrasi, CTA menempel bawah.
/// Daftar/Masuk selalu tersedia (tidak menunggu slide terakhir).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      title: 'Cari, sepakati, dan bayar dalam satu aplikasi',
      body:
          'Temukan asisten rumah tangga atau lowongan kerja yang cocok '
          'tanpa perantara.',
    ),
    (
      title: 'Semua pengguna terverifikasi',
      body:
          'KTP dan selfie setiap pengguna diperiksa petugas. Lihat segel '
          'verifikasi dan rating sebelum menyepakati apa pun.',
    ),
    (
      title: 'Dana aman, privasi terjaga',
      body:
          'Dana ditahan dengan aman dan dicairkan setelah pekerjaan selesai. '
          'Kontak pribadi disembunyikan sampai pembayaran dilakukan.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _art(int i) => switch (i) {
    0 => const WelcomeIllustration(size: 260),
    1 => const VerifyIllustration(size: 240),
    _ => const MoneySafeIllustration(size: 240),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppScaffold(
      glow: true,
      bottomNavigationBar: PinnedActionsBar(
        children: [
          AppButton(
            key: K.welcomeRegister,
            label: 'Daftar',
            large: true,
            onPressed: () => context.push(Routes.register),
          ),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            key: K.welcomeLogin,
            label: 'Masuk',
            large: true,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.login),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpace.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PramuMark(size: 40),
              const SizedBox(width: AppSpace.s8),
              Semantics(
                header: true,
                child: Text(
                  'Pramu',
                  style: AppText.wordmark(size: 30, color: t.textPrimary),
                ),
              ),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _art(i),
                        const SizedBox(height: AppSpace.s24),
                        Text(
                          _slides[i].title,
                          style: context.text.h1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpace.s12),
                        Text(
                          _slides[i].body,
                          style: context.text.body.copyWith(color: t.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: 'Halaman ${_index + 1} dari ${_slides.length}',
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: context.motion(AppMotion.base),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? t.primary
                            : t.borderStrong.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s16),
        ],
      ),
    );
  }
}
