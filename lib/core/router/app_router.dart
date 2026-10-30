import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Rute aplikasi. Layar S-01–S-20 (brief UI/UX v2 §6) ditambahkan per modul
/// mengikuti urutan kerja Docs/15 §4.4, bersama deep link yang divalidasi (Docs/19 M5).
final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const SedangDibangunScreen())],
  ),
);

/// Layar sementara selama domain baru dibangun (Docs/15 §4.4 langkah 1).
class SedangDibangunScreen extends StatelessWidget {
  const SedangDibangunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // shortcut: teks belum lewat l10n; layar ini dihapus saat S-01 dibangun (langkah 3).
    return const AppScaffold(
      body: Center(
        child: EmptyState(
          title: 'Pramu',
          message: 'Aplikasi sedang dibangun ulang.',
        ),
      ),
    );
  }
}
