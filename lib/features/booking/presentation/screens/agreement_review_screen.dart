import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/booking/presentation/widgets/booking_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-71 Tinjau kesepakatan (setuju dua arah).
class AgreementReviewScreen extends ConsumerStatefulWidget {
  const AgreementReviewScreen({super.key, required this.agreementId});
  final String agreementId;

  @override
  ConsumerState<AgreementReviewScreen> createState() => _State();
}

class _State extends ConsumerState<AgreementReviewScreen> with ApiActionMixin {
  void _reload() => ref.invalidate(agreementProvider(widget.agreementId));

  Future<void> _approve(Agreement a, Role role) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Setujui kesepakatan?',
      message:
          'Tarif ${formatRupiah(a.rate)} per periode (${a.unit.label}), '
          '${a.periodCount} periode, mulai ${formatDate(a.startDate)}. '
          'Setelah kedua pihak setuju, kesepakatan dikunci.',
      confirmLabel: 'Setuju',
    );
    if (!ok || !mounted) return;
    await act(
      ref.read(agreementProvider(widget.agreementId).notifier).approve,
      onConflict: _reload,
    );
  }

  Future<void> _counter(Agreement a) async {
    await context.push(Routes.agreementNew(a.applicationId));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ref.watch(sessionProvider.select((s) => s.activeRole)) ?? Role.seeker;
    return AppScaffold(
      title: 'Tinjau kesepakatan',
      body: AsyncBody<AgreementView>(
        value: ref.watch(agreementProvider(widget.agreementId)),
        onRetry: _reload,
        data: (context, v) => v.agreement.isAgreed
            ? _Done(a: v.agreement)
            : _Body(
                view: v,
                role: role,
                busy: busy,
                canAct: canAct,
                error: actionError,
                onApprove: () => _approve(v.agreement, role),
                onCounter: () => _counter(v.agreement),
              ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.a});
  final Agreement a;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: LucideIcons.circleCheck,
    title: 'Kontrak dibuat',
    message: 'Kedua pihak sudah setuju. Tagihan periode pertama siap dibayar.',
    actionLabel: a.bookingId == null ? null : 'Lihat kontrak',
    onAction: a.bookingId == null
        ? null
        : () => context.pushReplacement(Routes.bookingDetail(a.bookingId!)),
  );
}

class _Term extends StatelessWidget {
  const _Term(this.label, this.value, {this.before});
  final String label;
  final String value;
  final String? before;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final changed = before != null;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $value${changed ? ', berubah, sebelumnya $before' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: context.text.body.copyWith(color: t.textMuted),
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (changed) ...[
                        Icon(LucideIcons.pencil, size: 16, color: t.warning),
                        const SizedBox(width: AppSpace.s4),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          style: context.text.body.copyWith(
                            fontWeight: changed ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (changed)
                    Text(
                      'Sebelumnya: $before',
                      style: context.text.caption.copyWith(color: t.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.view,
    required this.role,
    required this.busy,
    required this.canAct,
    required this.error,
    required this.onApprove,
    required this.onCounter,
  });

  final AgreementView view;
  final Role role;
  final bool busy;
  final bool canAct;
  final dynamic error;
  final VoidCallback onApprove;
  final VoidCallback onCounter;

  @override
  Widget build(BuildContext context) {
    final a = view.agreement;
    final b = view.before;
    String? diff(bool changed, String old) => changed ? old : null;
    final seeker = role == Role.seeker;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Versi ${a.version}', style: context.text.h2),
              ),
              Text(
                'Diusulkan ${a.proposedBy == Role.seeker ? 'Pencari' : 'Asisten'}',
                style: context.text.bodySm,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          if (b != null)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.s8),
              child: PrivacyNote(
                'Syarat bertanda pensil berubah dari versi yang Anda lihat sebelumnya.',
              ),
            ),
          _Term(
            'Tarif per periode',
            formatRupiah(a.rate),
            before: diff(
              b != null && b.rate != a.rate,
              formatRupiah(b?.rate ?? 0),
            ),
          ),
          _Term(
            'Siklus bayar',
            a.unit.label,
            before: diff(b != null && b.unit != a.unit, b?.unit.label ?? ''),
          ),
          _Term(
            'Jumlah periode',
            '${a.periodCount} periode',
            before: diff(
              b != null && b.count != a.periodCount,
              '${b?.count} periode',
            ),
          ),
          _Term(
            'Tanggal mulai',
            formatDate(a.startDate),
            before: diff(
              b != null && b.start != a.startDate,
              b == null ? '' : formatDate(b.start),
            ),
          ),
          const SectionHeader('Rincian biaya'),
          FeeBreakdown(rows: contractFeeRows(a.fees, role)),
          const SectionHeader('Persetujuan'),
          for (final r in Role.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${r == Role.seeker ? 'Pencari' : 'Asisten'}'
                      '${r == role ? ' (Anda)' : ''}',
                      style: context.text.body,
                    ),
                  ),
                  StatusChip(
                    label: a.approvedBy(r) ? 'Setuju' : 'Belum setuju',
                    tone: a.approvedBy(r)
                        ? StatusTone.success
                        : StatusTone.neutral,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.s16),
          if (error != null) ActionErrorBox(error: error),
          if (a.canApprove(role))
            AppButton(
              key: K.agreementApprove,
              label: 'Setuju',
              large: true,
              loading: busy,
              onPressed: canAct ? onApprove : null,
            )
          else
            Text(
              seeker
                  ? 'Anda sudah setuju. Menunggu persetujuan Asisten.'
                  : 'Anda sudah setuju. Menunggu persetujuan Pencari.',
              style: context.text.body,
            ),
          if (a.canCounter(role)) ...[
            const SizedBox(height: AppSpace.s8),
            AppButton(
              key: K.agreementCounter,
              label: 'Ajukan balik',
              variant: AppButtonVariant.secondary,
              onPressed: busy ? null : onCounter,
            ),
          ],
        ],
      ),
    );
  }
}
