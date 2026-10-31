import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/router/arah.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/akun/akun_screen.dart';
import 'package:pramu_apps/features/akun/ganti_nomor_screen.dart';
import 'package:pramu_apps/features/akun/masuk_screen.dart';
import 'package:pramu_apps/features/akun/onboarding_screens.dart';
import 'package:pramu_apps/features/beranda/beranda_screen.dart';
import 'package:pramu_apps/features/booking/booking_screens.dart';
import 'package:pramu_apps/features/interaksi/interaksi_screens.dart';
import 'package:pramu_apps/features/jelajah/jelajah_screen.dart';
import 'package:pramu_apps/features/job/job_screens.dart';
import 'package:pramu_apps/features/penugasan/penugasan_screens.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';

/// Rute aplikasi. Jalur rinci memakai nama sumber API (`/booking/{id}`, `/penugasan/{id}`, …) agar `tujuan`
/// dari notifikasi dan kartu tindakan bisa dibuka langsung; id yang bukan UUID ditolak di [arahkan].
final routerProvider = Provider<GoRouter>((ref) {
  final ubah = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => ubah.value++);
  ref.listen(peranAktifProvider, (_, _) => ubah.value++);
  ref.onDispose(ubah.dispose);

  return GoRouter(
    initialLocation: '/beranda',
    refreshListenable: ubah,
    redirect: (_, state) => arahkan(
      ref.read(sessionProvider),
      state.matchedLocation,
      peran: ref.read(peranAktifProvider),
    ),
    errorBuilder: (_, _) => const _TidakDitemukan(),
    routes: [
      GoRoute(path: '/memuat', builder: (_, _) => const _Memuat()),
      GoRoute(path: '/masuk', builder: (_, _) => const MasukScreen()),
      GoRoute(
        path: '/persetujuan',
        builder: (_, _) => const PersetujuanScreen(),
      ),
      GoRoute(path: '/peran', builder: (_, _) => const PeranScreen()),
      GoRoute(path: '/lanjutkan', builder: (_, _) => const LanjutkanScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Kerangka(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/beranda',
                builder: (_, _) => const BerandaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/job', builder: (_, _) => const TabJobScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/booking',
                builder: (_, _) => const BookingDaftarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/penugasan',
                builder: (_, _) => const PenugasanDaftarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/akun', builder: (_, _) => const AkunScreen()),
            ],
          ),
        ],
      ),
      GoRoute(path: '/jelajah', builder: (_, _) => const JelajahScreen()),
      GoRoute(path: '/akun/nomor', builder: (_, _) => const GantiNomorScreen()),
      GoRoute(path: '/job/buat', builder: (_, _) => const BuatJobScreen()),
      GoRoute(
        path: '/job/:id',
        builder: (_, s) => JobDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, s) => BookingDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/penugasan/:id',
        builder: (_, s) => PenugasanDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/percakapan',
        builder: (_, _) => const PercakapanDaftarScreen(),
      ),
      GoRoute(
        path: '/percakapan/:id',
        builder: (_, s) => PercakapanScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/notifikasi', builder: (_, _) => const NotifikasiScreen()),
    ],
  );
});

class _Kerangka extends ConsumerWidget {
  const _Kerangka({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final majikan = ref.watch(peranAktifProvider) == Peran.majikan;
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNav(
        role: majikan ? AppRole.seeker : AppRole.assistant,
        index: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          const AppNavItem(icon: LucideIcons.house, label: 'Beranda'),
          AppNavItem(
            icon: majikan ? LucideIcons.briefcase : LucideIcons.search,
            label: majikan ? 'Job' : 'Cari job',
          ),
          const AppNavItem(icon: LucideIcons.send, label: 'Ajuan'),
          const AppNavItem(
            icon: LucideIcons.clipboardCheck,
            label: 'Pekerjaan',
          ),
          const AppNavItem(icon: LucideIcons.user, label: 'Akun'),
        ],
      ),
    );
  }
}

/// Layar saat sesi dimuat; bila GET /me gagal (mis. jaringan), tampilkan galat dengan tombol ulangi.
class _Memuat extends ConsumerWidget {
  const _Memuat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sessionProvider);
    return AppScaffold(
      body: sesi.hasError
          ? Center(
              child: ErrorState(
                message: pesanGalat(sesi.error!),
                onRetry: () => ref.invalidate(sessionProvider),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _TidakDitemukan extends StatelessWidget {
  const _TidakDitemukan();

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Pramu',
    body: EmptyState(
      title: 'Halaman tidak ditemukan',
      message: 'Tautan ini tidak bisa dibuka.',
      actionLabel: 'Ke Beranda',
      onAction: () => context.go('/beranda'),
    ),
  );
}
