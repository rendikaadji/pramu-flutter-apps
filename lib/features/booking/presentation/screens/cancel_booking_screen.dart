import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/flow_refresh.dart';

const _reasons = [
  'Pekerjaan tidak sesuai kesepakatan',
  'Jadwal atau kebutuhan berubah',
  'Saya tidak lagi membutuhkan asisten',
  'Alasan lain',
];

/// M-77 Batalkan kontrak. Tanpa refund: Pramu tidak menahan dana, gaji diselesaikan langsung antar pihak.
class CancelBookingScreen extends ConsumerStatefulWidget {
  const CancelBookingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<CancelBookingScreen> createState() => _State();
}

class _State extends ConsumerState<CancelBookingScreen> with ApiActionMixin {
  int? _reason;

  Future<void> _cancel() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Batalkan kontrak?',
      message:
          'Periode yang belum selesai akan dibatalkan. Gaji untuk pekerjaan '
          'yang sudah dijalani diselesaikan langsung dengan pihak lain.',
      confirmLabel: 'Batalkan kontrak',
      cancelLabel: 'Tidak jadi',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref
          .read(bookingRepositoryProvider)
          .cancel(widget.bookingId, reason: _reasons[_reason!]),
      onConflict: () => ref.invalidate(bookingProvider(widget.bookingId)),
    );
    if (!mounted || !done) return;
    invalidateFlow(ref.invalidate);
    AppSnack.show(context, 'Kontrak dibatalkan.');
    context.canPop()
        ? context.pop(true)
        : context.go(Routes.bookingDetail(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Batalkan kontrak',
      body: SingleChildScrollView(
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
            const SizedBox(height: AppSpace.s8),
            const PrivacyNote('Pembatalan tidak bisa diurungkan.'),
            const SizedBox(height: AppSpace.s16),
            if (actionError != null) ActionErrorBox(error: actionError!),
            AppButton(
              key: K.cancelSubmit,
              label: 'Batalkan kontrak',
              variant: AppButtonVariant.danger,
              large: true,
              loading: busy,
              onPressed: canAct && _reason != null ? _cancel : null,
            ),
          ],
        ),
      ),
    );
  }
}
