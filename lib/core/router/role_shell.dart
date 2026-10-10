import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';

typedef TabSpec = ({String id, String label, IconData icon, String path});

/// Tab bawah per peran (UIUX §5.1): Pencari 4, Pelamar 5.
const seekerTabs = <TabSpec>[
  (
    id: 'home',
    label: 'Beranda',
    icon: LucideIcons.house,
    path: Routes.seekerHome,
  ),
  (
    id: 'search',
    label: 'Cari',
    icon: LucideIcons.search,
    path: Routes.seekerSearch,
  ),
  (
    id: 'jobs',
    label: 'Pekerjaan',
    icon: LucideIcons.briefcase,
    path: Routes.seekerJobs,
  ),
  (
    id: 'chat',
    label: 'Pesan',
    icon: LucideIcons.messageSquare,
    path: Routes.seekerChat,
  ),
];

const assistantTabs = <TabSpec>[
  (
    id: 'home',
    label: 'Beranda',
    icon: LucideIcons.house,
    path: Routes.assistantHome,
  ),
  (
    id: 'listings',
    label: 'Lowongan',
    icon: LucideIcons.search,
    path: Routes.assistantListings,
  ),
  (
    id: 'jobs',
    label: 'Pekerjaan',
    icon: LucideIcons.briefcase,
    path: Routes.assistantJobs,
  ),
  (
    id: 'chat',
    label: 'Pesan',
    icon: LucideIcons.messageSquare,
    path: Routes.assistantChat,
  ),
  (
    id: 'profile',
    label: 'Profil',
    icon: LucideIcons.user,
    path: Routes.assistantAccount,
  ),
];

List<TabSpec> tabsFor(Role role) =>
    role == Role.seeker ? seekerTabs : assistantTabs;

/// Cangkang bottom-nav sementara. Dapat diganti komponen `shared/app_ui` tanpa mengubah router.
class RoleShell extends StatelessWidget {
  const RoleShell({super.key, required this.role, required this.shell});

  final Role role;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final tabs = tabsFor(role);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              key: K.tab(t.id),
              icon: Icon(t.icon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
