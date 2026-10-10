import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/report/presentation/state/report_state.dart';
import 'package:pramu_apps/features/report/presentation/widgets/evidence_picker.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _steps = [
  (ReportStatus.received, 'Diterima'),
  (ReportStatus.reviewing, 'Ditinjau'),
  (ReportStatus.needsInfo, 'Butuh info'),
  (ReportStatus.decided, 'Diputuskan'),
];

/// Teks status persetujuan berbagi chat.
String shareLabel(ChatShareConsent s, DateTime now) {
  if (s.revoked) return 'Persetujuan dicabut';
  if (!s.expiresAt.isAfter(now)) return 'Persetujuan kedaluwarsa';
  return 'Dibagikan sampai ${formatDate(s.expiresAt)}';
}

/// M-97 Status laporan.
class ReportStatusScreen extends ConsumerStatefulWidget {
  const ReportStatusScreen({super.key, required this.reportId});
  final String reportId;

  @override
  ConsumerState<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends ConsumerState<ReportStatusScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.isConflict) {
        await ConfirmDialog.show(
          context,
          title: 'Data sudah berubah',
          message: e.message,
          confirmLabel: 'Muat ulang',
          cancelLabel: 'Tutup',
        );
        if (mounted) ref.invalidate(reportProvider(widget.reportId));
      } else {
        AppSnack.show(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addEvidence({required bool camera}) => _run(() async {
    final p = await ref.read(evidencePickerProvider).pick(camera: camera);
    if (p == null) return;
    try {
      await ref.read(reportProvider(widget.reportId).notifier).addEvidence([p]);
      if (mounted) AppSnack.show(context, 'Bukti ditambahkan.', success: true);
    } finally {
      unawaited(deleteTemp(p));
    }
  });

  Future<void> _revoke() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Cabut persetujuan?',
      message: 'Tim kami tidak bisa lagi melihat percakapan ini.',
      confirmLabel: 'Cabut persetujuan',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref.read(reportProvider(widget.reportId).notifier).revokeShare(),
    );
  }

  Future<void> _chooseSource() async {
    final camera = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'Ambil foto',
                icon: LucideIcons.camera,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Dari galeri',
                icon: LucideIcons.images,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (camera != null) await _addEvidence(camera: camera);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportProvider(widget.reportId));
    final t = context.tokens;
    return AppScaffold(
      title: 'Status laporan',
      scrollable: true,
      body: async.when(
        loading: () => Semantics(
          label: 'Memuat',
          child: const Column(
            children: [
              AppSkeleton.box(120),
              SizedBox(height: AppSpace.s12),
              AppSkeleton.box(160),
            ],
          ),
        ),
        error: (e, _) => ApiErrorView(
          error: asApiException(e),
          onRetry: () => ref.invalidate(reportProvider(widget.reportId)),
        ),
        data: (r) {
          final share = r.share;
          final now = DateTime.now().toUtc();
          final shareActive =
              share != null && !share.revoked && share.expiresAt.isAfter(now);
          final canShare =
              share == null && r.status.canAddEvidence && r.bookingId != null;
          final current = _steps.indexWhere((s) => s.$1 == r.status);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.status == ReportStatus.received) ...[
                const Center(child: SuccessIllustration(size: 160)),
                const SizedBox(height: AppSpace.s8),
                Center(
                  child: Text(
                    'Laporan Anda sudah kami terima',
                    style: context.text.h2,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
              ],
              Row(
                children: [
                  Expanded(child: Text(r.type.label, style: context.text.h2)),
                  StatusChip(
                    label: r.status.label,
                    tone: r.status == ReportStatus.decided
                        ? StatusTone.success
                        : StatusTone.info,
                  ),
                ],
              ),
              Text(
                'Dikirim ${formatDateTime(r.createdAt)}',
                style: context.text.caption.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: AppSpace.s12),
              Text(r.description, style: context.text.body),
              const SizedBox(height: AppSpace.s16),
              Semantics(
                container: true,
                label: 'Status saat ini: ${r.status.label}',
                child: Column(
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.s8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              i < current || r.status == ReportStatus.decided
                                  ? LucideIcons.circleCheck
                                  : i == current
                                  ? LucideIcons.circleDot
                                  : LucideIcons.circle,
                              color: i <= current ? t.primary : t.textSubtle,
                            ),
                            const SizedBox(width: AppSpace.s12),
                            Text(
                              _steps[i].$2,
                              style: context.text.body.copyWith(
                                fontWeight: i == current
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (r.decision != null) ...[
                const SizedBox(height: AppSpace.s12),
                AppCard(
                  color: t.successContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Putusan', style: context.text.h3),
                      const SizedBox(height: AppSpace.s4),
                      Text(r.decision!, style: context.text.body),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.s16),
              Text('Persetujuan berbagi percakapan', style: context.text.h3),
              const SizedBox(height: AppSpace.s8),
              Text(
                share == null
                    ? 'Belum ada percakapan yang dibagikan.'
                    : shareLabel(share, now),
                style: context.text.body,
              ),
              const SizedBox(height: AppSpace.s16),
              if (r.status.canAddEvidence)
                AppButton(
                  key: K.reportAddEvidence,
                  label: 'Tambah bukti',
                  icon: LucideIcons.imagePlus,
                  variant: AppButtonVariant.secondary,
                  loading: _busy,
                  onPressed: _busy ? null : _chooseSource,
                ),
              if (canShare) ...[
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  label: 'Bagikan percakapan',
                  icon: LucideIcons.share2,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy
                      ? null
                      : () => context.push(Routes.reportShare(r.id)),
                ),
              ],
              if (shareActive) ...[
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  key: K.reportRevokeShare,
                  label: 'Cabut persetujuan',
                  variant: AppButtonVariant.danger,
                  loading: _busy,
                  onPressed: _busy ? null : _revoke,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
