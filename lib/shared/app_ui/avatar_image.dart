import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Foto profil asli; bila kosong/gagal dimuat tampil inisial nama (tanpa ilustrasi generik).
class AvatarImage extends StatelessWidget {
  const AvatarImage({super.key, required this.name, this.url, this.size = 40});

  final String name;
  final String? url;
  final double size;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fallback = ColoredBox(
      color: t.primaryContainer,
      child: Center(
        child: Text(
          initials(name),
          style: context.text.label.copyWith(
            color: t.primary,
            fontSize: size * .4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      label: 'Foto $name',
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: (url == null || url!.isEmpty)
              ? fallback
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  cacheWidth: (size * dpr).round(),
                  errorBuilder: (_, _, _) => fallback,
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : ColoredBox(color: t.sunken),
                ),
        ),
      ),
    );
  }
}
