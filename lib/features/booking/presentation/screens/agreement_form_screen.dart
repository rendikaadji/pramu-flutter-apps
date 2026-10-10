import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/booking/presentation/widgets/booking_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/wib_picker.dart';

/// M-70 Susun kesepakatan. Bila sudah ada versi berjalan -> mode "Ajukan balik".
class AgreementFormScreen extends ConsumerWidget {
  const AgreementFormScreen({super.key, required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(agreementDraftProvider(applicationId));
    return AppScaffold(
      title: 'Susun kesepakatan',
      body: AsyncBody<Agreement?>(
        value: draft,
        onRetry: () => ref.invalidate(agreementDraftProvider(applicationId)),
        data: (context, existing) {
          if (existing != null && existing.isAgreed) {
            return EmptyState(
              icon: LucideIcons.circleCheck,
              title: 'Kesepakatan sudah disetujui',
              message: 'Kontrak sudah dibuat dan tidak dapat diubah.',
              actionLabel: existing.bookingId == null ? null : 'Lihat kontrak',
              onAction: existing.bookingId == null
                  ? null
                  : () => context.pushReplacement(
                      Routes.bookingDetail(existing.bookingId!),
                    ),
            );
          }
          return _Form(applicationId: applicationId, existing: existing);
        },
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.applicationId, this.existing});
  final String applicationId;
  final Agreement? existing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> with ApiActionMixin {
  late final _rate = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.rate}',
  );
  late PeriodUnit _unit = widget.existing?.unit ?? PeriodUnit.monthly;
  late int _count = widget.existing?.periodCount ?? 1;
  late DateTime? _start = widget.existing?.startDate;
  (int, int)? _query;
  Timer? _debounce;
  String? _localRate;
  String? _localStart;

  @override
  void initState() {
    super.initState();
    _rate.addListener(_schedule);
    _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rate.dispose();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final r = parseRupiah(_rate.text);
      setState(() => _query = r == null || r <= 0 ? null : (r, _count));
    });
  }

  Future<void> _submit() async {
    final rate = parseRupiah(_rate.text);
    setState(() {
      _localRate = rate == null || rate <= 0
          ? 'Tarif harus lebih dari Rp0'
          : null;
      _localStart = _start == null ? 'Pilih tanggal mulai' : null;
    });
    if (_localRate != null || _localStart != null) return;
    final input = AgreementInput(
      rate: rate!,
      unit: _unit,
      periodCount: _count,
      startDate: _start!,
    );
    final repo = ref.read(bookingRepositoryProvider);
    final existing = widget.existing;
    Agreement? done;
    final ok = await act(
      () async => done = existing == null
          ? await repo.propose(widget.applicationId, input)
          : await repo.counter(existing.id, input),
      onConflict: () =>
          ref.invalidate(agreementDraftProvider(widget.applicationId)),
    );
    if (!ok || !mounted) return;
    ref.invalidate(agreementDraftProvider(widget.applicationId));
    if (existing != null && context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement(Routes.agreementReview(done!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final role =
        ref.watch(sessionProvider.select((s) => s.activeRole)) ?? Role.seeker;
    final counter = widget.existing != null;
    final preview = _query == null
        ? null
        : ref.watch(feePreviewProvider(_query!));
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpace.s8, bottom: AppSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (counter)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.s12),
              child: PrivacyNote(
                'Ajukan balik membuat versi baru. Persetujuan sebelumnya direset.',
              ),
            ),
          if (actionError != null) ActionErrorBox(error: actionError!),
          AppTextField(
            key: K.agreementRate,
            controller: _rate,
            label: 'Tarif per periode',
            prefixText: 'Rp',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            errorText: _localRate ?? fieldError('rate'),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Siklus bayar', style: context.text.label),
          const SizedBox(height: AppSpace.s8),
          SegmentedButton<PeriodUnit>(
            segments: const [
              ButtonSegment(value: PeriodUnit.daily, label: Text('Harian')),
              ButtonSegment(value: PeriodUnit.weekly, label: Text('Mingguan')),
              ButtonSegment(value: PeriodUnit.monthly, label: Text('Bulanan')),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Jumlah periode', style: context.text.label),
          Semantics(
            label: 'Jumlah periode $_count',
            child: Row(
              children: [
                AppIconButton(
                  key: K.agreementPeriodMinus,
                  icon: LucideIcons.minus,
                  label: 'Kurangi periode',
                  onPressed: _count > 1
                      ? () {
                          setState(() => _count--);
                          _schedule();
                        }
                      : null,
                ),
                SizedBox(
                  width: AppSpace.s48,
                  child: Text(
                    '$_count',
                    textAlign: TextAlign.center,
                    style: context.text.h3,
                  ),
                ),
                AppIconButton(
                  key: K.agreementPeriodPlus,
                  icon: LucideIcons.plus,
                  label: 'Tambah periode',
                  onPressed: _count < 24
                      ? () {
                          setState(() => _count++);
                          _schedule();
                        }
                      : null,
                ),
              ],
            ),
          ),
          if (fieldError('period_count') != null)
            FieldErrorText(fieldError('period_count')!),
          const SizedBox(height: AppSpace.s16),
          Text('Tanggal mulai', style: context.text.label),
          const SizedBox(height: AppSpace.s8),
          AppButton(
            key: K.agreementStart,
            label: _start == null ? 'Pilih tanggal' : formatDate(_start!),
            icon: LucideIcons.calendar,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final d = await pickWibDate(context, initial: _start);
              if (d != null) setState(() => _start = d);
            },
          ),
          if ((_localStart ?? fieldError('start_date')) != null)
            FieldErrorText((_localStart ?? fieldError('start_date'))!),
          const SizedBox(height: AppSpace.s24),
          SectionHeader(
            role == Role.seeker
                ? 'Perkiraan biaya'
                : 'Perkiraan yang Anda terima',
          ),
          if (preview == null)
            Text(
              'Isi tarif untuk melihat perkiraan.',
              style: context.text.body.copyWith(color: t.textMuted),
            )
          else
            preview.when(
              loading: () => Semantics(
                label: 'Memuat',
                child: const AppSkeleton.line(width: 200),
              ),
              error: (_, _) => Text(
                'Perkiraan belum tersedia. Angka final ditampilkan setelah usulan dikirim.',
                style: context.text.body.copyWith(color: t.textMuted),
              ),
              data: (f) => FeeBreakdown(rows: contractFeeRows(f, role)),
            ),
          const SizedBox(height: AppSpace.s4),
          Text(
            'Ini hanya perkiraan. Angka final dihitung server.',
            style: context.text.caption.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpace.s16),
          const PrivacyNote(
            'Setelah kedua pihak setuju, kesepakatan dikunci dan tidak bisa diubah.',
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.agreementSubmit,
            label: counter ? 'Kirim usulan balik' : 'Kirim usulan',
            large: true,
            loading: busy,
            onPressed: canAct ? _submit : null,
          ),
        ],
      ),
    );
  }
}
