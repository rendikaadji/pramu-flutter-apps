import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'header_glow.dart';

/// Kerangka layar: SafeArea, margin horizontal 16 (>= 600dp: 24), konten maks 600dp
/// di tengah pada layar besar. `scrollable` untuk form; daftar mengelola scroll sendiri
/// (pakai `padded: false` bila daftar mengatur padding sendiri). `banner` (mis. OfflineBanner)
/// tampil penuh lebar di atas konten.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.appBar,
    this.banner,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.scrollable = false,
    this.padded = true,
    this.glow = false,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;

  /// Menimpa AppBar bawaan dari `title`.
  final PreferredSizeWidget? appBar;
  final Widget? banner;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool scrollable;
  final bool padded;

  /// Latar `HeaderGlow` biru muda lembut di atas layar (beranda, profil).
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final bar =
        appBar ??
        (title == null ? null : AppBar(title: Text(title!), actions: actions));
    final h = MediaQuery.sizeOf(context).width >= 600
        ? AppSpace.s24
        : AppSpace.s16;
    Widget content = padded
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: h),
            child: body,
          )
        : body;
    if (scrollable) {
      content = SingleChildScrollView(
        padding: const EdgeInsets.only(top: AppSpace.s8, bottom: AppSpace.s24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      );
    }
    content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpace.maxContent),
        child: content,
      ),
    );
    final scaffold = Scaffold(
      backgroundColor: glow ? Colors.transparent : null,
      appBar: bar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: bar == null,
        bottom: bottomNavigationBar == null,
        child: banner == null
            ? content
            : Column(
                children: [
                  banner!,
                  Expanded(child: content),
                ],
              ),
      ),
    );
    if (!glow) return scaffold;
    return ColoredBox(
      color: context.tokens.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: HeaderGlow()),
          scaffold,
        ],
      ),
    );
  }
}
