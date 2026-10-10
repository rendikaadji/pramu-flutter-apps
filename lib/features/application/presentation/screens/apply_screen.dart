import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _templates = {
  'Tertarik & siap':
      'Halo, saya tertarik dan siap bekerja sesuai kebutuhan Anda.',
  'Berpengalaman': 'Saya berpengalaman di bidang ini dan bisa mulai sesuai tanggal yang diminta.',
};

/// M-43 Form lamar. Draf isian disimpan lokal (tanpa data sensitif) sampai terkirim.
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<ApplyScreen> createState() => _State();
}

class _State extends ConsumerState<ApplyScreen> with ApiActionMixin {
  final _message = TextEditingController();
  final _rate = TextEditingController();
  final _answers = <TextEditingController>[];
  final _local = <String, String>{};
  bool _ready = false;

  String get _draftKey => 'apply_draft_${widget.listingId}';

  @override
  void dispose() {
    for (final c in [_message, _rate, ..._answers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(ApplyContext c) {
    if (_ready) return;
    _ready = true;
    Map<String, dynamic>? draft;
    try {
      final raw = ref.read(prefsProvider).getString(_draftKey);
      if (raw != null) draft = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      draft = null;
    }
    _message.text = draft?['message'] as String? ?? '';
    _rate.text =
        draft?['rate'] as String? ?? '${c.defaultRate ?? c.listing.budgetMin}';
    final saved = List<String>.from(draft?['answers'] as List? ?? const []);
    for (var i = 0; i < c.listing.screeningQuestions.length; i++) {
      _answers.add(
        TextEditingController(text: i < saved.length ? saved[i] : ''),
      );
    }
  }

  void _saveDraft() {
    ref
        .read(prefsProvider)
        .setString(
          _draftKey,
          jsonEncode({
            'message': _message.text,
            'rate': _rate.text,
            'answers': [for (final c in _answers) c.text],
          }),
        );
  }

  void _changed(String key) {
    _saveDraft();
    if (_local.containsKey(key)) setState(() => _local.remove(key));
  }

  Future<void> _submit(Listing l) async {
    final errors = <String, String>{};
    if (_message.text.trim().isEmpty) errors['message'] = 'Pesan wajib diisi';
    final rate = parseRupiah(_rate.text);
    if (rate == null || rate <= 0) {
      errors['proposed_rate'] = 'Tarif harus lebih dari 0';
    }
    for (var i = 0; i < _answers.length; i++) {
      if (_answers[i].text.trim().isEmpty) {
        errors['answer_$i'] = 'Jawaban wajib diisi';
      }
    }
    if (errors.isNotEmpty) {
      setState(() {
        _local
          ..clear()
          ..addAll(errors);
      });
      return;
    }
    Application? created;
    final ok = await act(() async {
      created = await ref
          .read(applicationRepositoryProvider)
          .apply(
            l.id,
            ApplyInput(
              message: _message.text.trim(),
              proposedRate: rate!,
              answers: [for (final c in _answers) c.text.trim()],
            ),
          );
    }, onConflict: () => ref.invalidate(applyContextProvider(l.id)));
    if (!ok || !mounted) return;
    ref.read(prefsProvider).remove(_draftKey);
    ref.invalidate(myApplicationsProvider);
    AppSnack.show(context, 'Lamaran terkirim', success: true);
    context.pushReplacement(Routes.applicationDetail(created!.id));
  }

  String? _err(String key) => _local[key] ?? fieldError(key);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(applyContextProvider(widget.listingId));
    return AppScaffold(
      title: 'Lamar pekerjaan',
      body: AsyncBody<ApplyContext>(
        value: async,
        onRetry: () => ref.invalidate(applyContextProvider(widget.listingId)),
        data: (ctx, c) {
          _init(c);
          final l = c.listing;
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [
              if (actionError != null)
                ActionErrorBox(error: actionError!, skckListingId: l.id),
              Text(l.title, style: context.text.h2),
              const SizedBox(height: AppSpace.s16),
              Wrap(
                spacing: AppSpace.s8,
                children: [
                  for (final e in _templates.entries)
                    ActionChip(
                      label: Text(e.key),
                      onPressed: () {
                        setState(() => _message.text = e.value);
                        _changed('message');
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s12),
              AppTextField(
                key: K.applyMessage,
                label: 'Pesan untuk pencari',
                controller: _message,
                maxLines: 4,
                maxLength: 500,
                errorText: _err('message'),
                onChanged: (_) => _changed('message'),
              ),
              const SizedBox(height: AppSpace.s16),
              AppTextField(
                key: K.applyRate,
                label: 'Tarif usulan per ${l.unit.label.toLowerCase()}',
                prefixText: 'Rp',
                controller: _rate,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _err('proposed_rate'),
                helper: 'Budget pencari ${budgetRange(l)}',
                onChanged: (_) => _changed('proposed_rate'),
              ),
              for (var i = 0; i < _answers.length; i++) ...[
                const SizedBox(height: AppSpace.s16),
                AppTextField(
                  label: l.screeningQuestions[i],
                  controller: _answers[i],
                  maxLines: 2,
                  maxLength: 200,
                  errorText: _err('answer_$i'),
                  onChanged: (_) => _changed('answer_$i'),
                ),
              ],
              const SizedBox(height: AppSpace.s24),
              AppButton(
                key: K.applySubmit,
                label: 'Kirim lamaran',
                large: true,
                loading: busy,
                onPressed: canAct ? () => _submit(l) : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

String budgetRange(Listing l) =>
    '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)}';
