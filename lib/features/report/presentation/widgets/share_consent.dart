import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/report/presentation/state/report_state.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _facts = <(IconData, String)>[
  (
    LucideIcons.messageCircle,
    'Hanya percakapan ini yang dibagikan, bukan chat lain.',
  ),
  (
    LucideIcons.users,
    'Hanya tim Pramu yang menangani kasus Anda yang bisa membacanya.',
  ),
  (
    LucideIcons.clock,
    'Berlaku 7 hari atau sampai kasus selesai, mana yang lebih dulu.',
  ),
  (LucideIcons.eye, 'Setiap akses dicatat, dan pihak lawan akan diberi tahu.'),
  (
    LucideIcons.undo2,
    'Anda bisa mencabutnya kapan saja di halaman Status laporan.',
  ),
];

/// Isi consent M-96. Memanggil [onDone] dengan true (dibagikan) / false (ditolak).
class ShareConsentBody extends ConsumerStatefulWidget {
  const ShareConsentBody({
    super.key,
    required this.reportId,
    required this.conversationId,
    required this.onDone,
  });

  final String reportId;
  final String conversationId;
  final ValueChanged<bool> onDone;

  @override
  ConsumerState<ShareConsentBody> createState() => _ShareConsentBodyState();
}

class _ShareConsentBodyState extends ConsumerState<ShareConsentBody> {
  bool _busy = false;
  String? _error;

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(reportProvider(widget.reportId).notifier)
          .share(widget.conversationId);
      if (mounted) widget.onDone(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    ref.watch(reportProvider(widget.reportId)); // jaga provider tetap hidup
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Bagikan percakapan ini?', style: context.text.h2),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          'Tim kami bisa membaca percakapan ini selama 7 hari agar laporan Anda dapat diproses. Anda bisa mencabutnya kapan saja.',
          style: context.text.body.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: AppSpace.s16),
        for (final (icon, text) in _facts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, size: 24, color: t.primary)),
                const SizedBox(width: AppSpace.s12),
                Expanded(child: Text(text, style: context.text.body)),
              ],
            ),
          ),
        if (_error != null) FieldErrorText(_error!),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          key: K.shareConsent,
          label: 'Setuju, bagikan',
          loading: _busy,
          onPressed: _busy ? null : _share,
        ),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          key: K.shareDecline,
          label: 'Lanjut tanpa berbagi',
          variant: AppButtonVariant.secondary,
          onPressed: _busy ? null : () => widget.onDone(false),
        ),
      ],
    );
  }
}

/// Bottom sheet M-96. Mengembalikan true bila dibagikan.
Future<bool> showShareConsentSheet(
  BuildContext context, {
  required String reportId,
  required String conversationId,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          0,
          AppSpace.s16,
          AppSpace.s16,
        ),
        child: ShareConsentBody(
          reportId: reportId,
          conversationId: conversationId,
          onDone: (v) => Navigator.pop(ctx, v),
        ),
      ),
    ),
  );
  return ok ?? false;
}
