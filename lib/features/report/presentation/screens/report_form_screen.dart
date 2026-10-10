import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/report/data/report_providers.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/report/presentation/state/report_state.dart';
import 'package:pramu_apps/features/report/presentation/widgets/evidence_list.dart';
import 'package:pramu_apps/features/report/presentation/widgets/evidence_picker.dart';
import 'package:pramu_apps/features/report/presentation/widgets/share_consent.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _types = [
  ReportType.behavior,
  ReportType.fraud,
  ReportType.payment,
  ReportType.workMismatch,
  ReportType.other,
];

/// M-95 Laporkan / ajukan sengketa. [bookingId]/[periodId] dari query (sudah divalidasi ULID).
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.bookingId, this.periodId});
  final String? bookingId;
  final String? periodId;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _desc = TextEditingController();
  final _paths = <String>[];
  ReportType _type = ReportType.other;
  bool _busy = false;
  String? _descError;
  String? _typeNote;

  String? get _booking => isUlid(widget.bookingId) ? widget.bookingId : null;
  String? get _period => isUlid(widget.periodId) ? widget.periodId : null;

  @override
  void initState() {
    super.initState();
    if (_period != null) _type = ReportType.payment;
  }

  @override
  void dispose() {
    _desc.dispose();
    for (final p in _paths) {
      deleteTemp(p);
    }
    super.dispose();
  }

  Future<void> _pick({required bool camera}) async {
    try {
      final p = await ref.read(evidencePickerProvider).pick(camera: camera);
      if (p != null && mounted) setState(() => _paths.add(p));
    } on Object {
      if (mounted) {
        AppSnack.show(context, 'Foto tidak dapat diambil. Coba lagi.');
      }
    }
  }

  Future<void> _submit() async {
    if (_desc.text.trim().length < 10) {
      setState(() => _descError = 'Jelaskan minimal 10 karakter.');
      return;
    }
    setState(() {
      _busy = true;
      _descError = null;
    });
    try {
      final r = await ref
          .read(reportRepositoryProvider)
          .submit(
            ReportInput(
              type: _type,
              description: _desc.text.trim(),
              bookingId: _booking,
              periodId: _period,
              evidencePaths: List.of(_paths),
            ),
          );
      ref.invalidate(reportListProvider);
      for (final p in _paths) {
        deleteTemp(p);
      }
      _paths.clear();
      if (!mounted) return;
      final router = GoRouter.of(context);
      String? conv;
      try {
        if (_booking != null) {
          conv = (await ref.read(bookingRepositoryProvider).booking(_booking!))
              .conversationId;
        }
      } on ApiException {
        conv = null;
      }
      if (conv != null && mounted) {
        await showShareConsentSheet(
          context,
          reportId: r.id,
          conversationId: conv,
        );
      }
      router.pushReplacement(Routes.reportStatus(r.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isValidation) {
        setState(() {
          _descError = e.fields['description']?.first;
          _typeNote = _descError == null ? e.message : null;
        });
      } else if (e.isConflict) {
        await ConfirmDialog.show(
          context,
          title: 'Data sudah berubah',
          message: e.message,
          confirmLabel: 'Mengerti',
          cancelLabel: 'Tutup',
        );
      } else if (e.status == 403 && e.code == 'VERIFICATION_REQUIRED') {
        context.push(Routes.verificationGate);
      } else {
        AppSnack.show(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final booking = _booking == null
        ? null
        : ref.watch(_bookingTitleProvider(_booking!)).value;
    return AppScaffold(
      title: 'Laporkan masalah',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking != null)
            AppCard(
              child: Row(
                children: [
                  const ExcludeSemantics(child: Icon(LucideIcons.briefcase)),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaksi terkait', style: context.text.caption),
                        Text(booking, style: context.text.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.s16),
          Semantics(
            header: true,
            child: Text('Jenis masalah', style: context.text.h3),
          ),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              for (final ty in _types)
                ChoiceChip(
                  key: K.reportType(ty.name),
                  label: Text(ty.label),
                  selected: _type == ty,
                  onSelected: _busy ? null : (_) => setState(() => _type = ty),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            key: K.reportDescription,
            label: 'Uraian kejadian',
            controller: _desc,
            maxLines: 5,
            maxLength: 1000,
            enabled: !_busy,
            errorText: _descError,
            keyboardType: TextInputType.multiline,
            helper: 'Ceritakan apa yang terjadi, kapan, dan dengan siapa.',
          ),
          const SizedBox(height: AppSpace.s8),
          Text('Bukti foto (opsional)', style: context.text.h3),
          const SizedBox(height: AppSpace.s8),
          EvidenceList(
            paths: _paths,
            busy: _busy,
            onPick: _pick,
            onRemove: (p) {
              setState(() => _paths.remove(p));
              deleteTemp(p);
            },
          ),
          const SizedBox(height: AppSpace.s16),
          if (_period != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: AppCard(
                color: t.warningContainer,
                borderColor: t.warning.withValues(alpha: .4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(LucideIcons.triangleAlert, color: t.warning),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Text(
                        'Kontrak dan periode ini dapat dibekukan sampai ada putusan. Dana tetap ditahan aman.',
                        style: context.text.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const PrivacyNote(
            'Setelah dikirim, tim kami meninjau laporan dan memberi kabar lewat notifikasi. Anda bisa menambah bukti dan memantau status di sini.',
          ),
          if (_typeNote != null) FieldErrorText(_typeNote!),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.reportSubmit,
            label: 'Laporkan masalah',
            large: true,
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

final _bookingTitleProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, id) async =>
      (await ref.read(bookingRepositoryProvider).booking(id)).listingTitle,
);
