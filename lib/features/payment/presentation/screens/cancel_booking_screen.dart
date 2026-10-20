import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/payment/data/payment_providers.dart';
import 'package:pramu_apps/features/payment/domain/payment_repository.dart';
import 'package:pramu_apps/features/payment/presentation/state/payment_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _reasons = [
  'Pekerjaan tidak sesuai kesepakatan',
  'Jadwal atau kebutuhan berubah',
  'Saya tidak lagi membutuhkan asisten',
  'Alasan lain',
];

/// M-77 Batalkan booking: angka refund dari server, tombol aktif hanya dengan data server.
class CancelBookingScreen extends ConsumerStatefulWidget {
  const CancelBookingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<CancelBookingScreen> createState() => _State();
}

class _State extends ConsumerState<CancelBookingScreen> with ApiActionMixin {
  int? _reason;

  Future<void> _cancel(RefundPreview pv) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Batalkan kontrak?',
      message:
          'Dana yang kembali ke Anda: ${formatRupiah(pv.refundToSeeker)}. '
          'Pembayaran untuk pekerjaan yang sudah dijalani tidak dikembalikan.',
      confirmLabel: 'Batalkan kontrak',
      cancelLabel: 'Tidak jadi',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref
          .read(paymentRepositoryProvider)
          .cancel(widget.bookingId, reason: _reasons[_reason!]),
      onConflict: () => ref.invalidate(cancelPreviewProvider(widget.bookingId)),
    );
    if (!mounted || !done) return;
    AppSnack.show(context, 'Kontrak dibatalkan.');
    context.canPop()
        ? context.pop(true)
        : context.go(Routes.bookingDetail(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(cancelPreviewProvider(widget.bookingId));
    return AppScaffold(
      title: 'Batalkan kontrak',
      body: AsyncBody<RefundPreview>(
        value: value,
        onRetry: () => ref.invalidate(cancelPreviewProvider(widget.bookingId)),
        skeleton: const DetailSkeleton(),
        data: (context, pv) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alasan pembatalan', style: context.text.h2),
              RadioGroup<int>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (var i = 0; i < _reasons.length; i++)
                      RadioListTile<int>(
                        key: K.cancelReason(i),
                        value: i,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_reasons[i]),
                      ),
                  ],
                ),
              ),
              if (fieldError('reason') != null)
                FieldErrorText(fieldError('reason')!),
              const SectionHeader('Perkiraan dana kembali'),
              FeeBreakdown(
                rows: [
                  FeeRow(
                    'Hak asisten untuk pekerjaan yang sudah dijalani',
                    formatRupiah(pv.assistantEntitlement),
                  ),
                  FeeRow(
                    'Kembali ke Anda',
                    formatRupiah(pv.refundToSeeker),
                    total: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s8),
              const PrivacyNote(
                'Pembatalan tidak bisa diurungkan. Angka pasti dihitung saat pembatalan diproses.',
              ),
              const SizedBox(height: AppSpace.s16),
              if (actionError != null) ActionErrorBox(error: actionError!),
              AppButton(
                key: K.cancelSubmit,
                label: 'Batalkan kontrak',
                variant: AppButtonVariant.danger,
                large: true,
                loading: busy,
                onPressed: canAct && _reason != null ? () => _cancel(pv) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
