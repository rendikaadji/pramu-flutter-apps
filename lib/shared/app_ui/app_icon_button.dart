import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tombol ikon 48dp. `label` wajib: dibacakan screen reader (Semantics).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    constraints: const BoxConstraints(
      minWidth: AppSpace.tap,
      minHeight: AppSpace.tap,
    ),
    icon: Icon(icon, size: 24, color: color, semanticLabel: label),
  );
}
