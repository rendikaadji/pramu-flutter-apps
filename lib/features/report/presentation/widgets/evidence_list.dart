import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Daftar foto bukti terpilih + tombol ambil/galeri. Maks [max] foto.
class EvidenceList extends StatelessWidget {
  const EvidenceList({
    super.key,
    required this.paths,
    required this.onPick,
    required this.onRemove,
    this.max = 3,
    this.busy = false,
  });

  final List<String> paths;
  final void Function({required bool camera}) onPick;
  final ValueChanged<String> onRemove;
  final int max;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final full = paths.length >= max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paths.length; i++)
          Row(
            children: [
              const ExcludeSemantics(child: Icon(LucideIcons.image, size: 24)),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text('Foto bukti ${i + 1}', style: context.text.body),
              ),
              AppIconButton(
                icon: LucideIcons.trash2,
                label: 'Hapus foto bukti ${i + 1}',
                onPressed: busy ? null : () => onRemove(paths[i]),
              ),
            ],
          ),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          children: [
            AppButton(
              label: 'Ambil foto',
              icon: LucideIcons.camera,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: full || busy ? null : () => onPick(camera: true),
            ),
            AppButton(
              label: 'Dari galeri',
              icon: LucideIcons.images,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: full || busy ? null : () => onPick(camera: false),
            ),
          ],
        ),
        if (full)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s4),
            child: Text(
              'Maksimal $max foto.',
              style: context.text.caption.copyWith(
                color: context.tokens.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
