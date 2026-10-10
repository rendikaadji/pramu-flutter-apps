import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Area aksi yang menempel di bawah layar (untuk `AppScaffold.bottomNavigationBar`):
/// SafeArea bawah, margin sama dengan konten, lebar maks 600dp, pemisah halus di atas.
class PinnedActionsBar extends StatelessWidget {
  const PinnedActionsBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final h = MediaQuery.sizeOf(context).width >= 600
        ? AppSpace.s24
        : AppSpace.s16;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.canvas,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpace.maxContent),
            child: Padding(
              padding: EdgeInsets.fromLTRB(h, AppSpace.s12, h, AppSpace.s12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
