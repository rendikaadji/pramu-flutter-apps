import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/verification/data/photo_service.dart';
import 'package:pramu_apps/features/verification/presentation/state/verification_state.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Foto profil milik sendiri (kedua peran): ketuk -> kamera / galeri / hapus.
/// File sementara selalu dihapus setelah unggah (MOB-SEC-05).
class ProfilePhoto extends ConsumerStatefulWidget {
  const ProfilePhoto({super.key, required this.user, this.size = 64});

  final AuthUser user;
  final double size;

  @override
  ConsumerState<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends ConsumerState<ProfilePhoto> {
  bool _busy = false;

  Future<void> _run(Future<String> Function() job) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final msg = await job();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } on PhotoException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(PhotoSource source) => _run(() async {
    final service = ref.read(photoServiceProvider);
    final photo = await service.capture(
      source,
      front: source == PhotoSource.camera,
    );
    if (photo == null) return 'Dibatalkan';
    try {
      await ref.read(sessionProvider.notifier).uploadPhoto(photo.path);
    } finally {
      await service.delete(photo);
    }
    return 'Foto profil diperbarui';
  });

  Future<void> _remove() => _run(() async {
    await ref.read(sessionProvider.notifier).removePhoto();
    return 'Foto profil dihapus';
  });

  Future<void> _openSheet() async {
    if (_busy) return;
    final hasPhoto = (widget.user.photoUrl ?? '').isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(LucideIcons.trash2, color: context.tokens.danger),
                title: Text(
                  'Hapus foto',
                  style: TextStyle(color: context.tokens.danger),
                ),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'camera':
        await _pick(PhotoSource.camera);
      case 'gallery':
        await _pick(PhotoSource.gallery);
      case 'remove':
        await _remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final u = widget.user;
    final s = widget.size;
    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      excludeSemantics: true,
      child: InkWell(
        key: const Key('profilePhoto'),
        onTap: _openSheet,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarImage(name: u.name, url: u.photoUrl, size: s),
              if (_busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.scrim,
                    ),
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.primaryContainer,
                    border: Border.all(color: t.canvas, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(LucideIcons.camera, size: 14, color: t.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
