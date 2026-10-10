import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;

  /// > 0 menampilkan badge angka (mis. pesan belum dibaca).
  final int badgeCount;
}

/// Bottom nav 4 (Pencari) / 5 (Asisten) item, ikon + label. Indikator dan ikon
/// terpilih diwarnai peran: Pencari = primary (biru), Asisten = assistant (teal).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
    this.role = AppRole.seeker,
  });

  final List<AppNavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = t.roleColor(role);
    final theme = Theme.of(context);
    Widget icon(AppNavItem i, Color c) => i.badgeCount > 0
        ? Badge.count(
            count: i.badgeCount,
            child: Icon(i.icon, color: c),
          )
        : Icon(i.icon, color: c);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      // Label bottom nav tidak boleh pecah; skala teks dibatasi 130%.
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: .85,
        maxScaleFactor: 1.3,
        child: NavigationBarTheme(
          data: theme.navigationBarTheme.copyWith(
            indicatorColor: t.roleContainer(role),
            iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(
                size: 24,
                color: s.contains(WidgetState.selected) ? tint : t.textMuted,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              if (i != index) HapticFeedback.selectionClick();
              onTap(i);
            },
            animationDuration: context.motion(AppMotion.base),
            destinations: [
              for (final i in items)
                NavigationDestination(
                  icon: icon(i, t.textMuted),
                  selectedIcon: icon(i, tint),
                  label: i.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
