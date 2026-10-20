import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/listing_card.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/flow_refresh.dart';

const _templates = {
  'Tertarik dan siap':
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
  String? _sentId;

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
    if (_message.text.trim().isEmpty) {
      errors['message'] = 'Tulis pesan singkat untuk pencari';
    }
    final rate = parseRupiah(_rate.text);
    if (rate == null || rate <= 0) {
      errors['proposed_rate'] = 'Isi tarif lebih dari Rp0';
    }
    for (var i = 0; i < _answers.length; i++) {
      if (_answers[i].text.trim().isEmpty) {
        errors['answer_$i'] = 'Jawab pertanyaan ini dulu';
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
    invalidateFlow(ref.invalidate);
    // Layar detail lowongan masih terpasang di bawah dan memakai provider turunan sendiri;
    // tanpa ini tombolnya tetap "Lamar sekarang" setelah berhasil melamar.
    ref.invalidate(myApplicationForListingProvider(l.id));
    ref.invalidate(listingDetailProvider(l.id));
    setState(() => _sentId = created!.id);
  }

  String? _err(String key) => _local[key] ?? fieldError(key);

  @override
  Widget build(BuildContext context) {
    final sent = _sentId;
    if (sent != null) {
      return AppScaffold(
        title: 'Lamar pekerjaan',
        glow: true,
        padded: false,
        body: SuccessView(
          title: 'Lamaran terkirim',
          message: 'Pencari akan memeriksa lamaran Anda. Kami kabari lewat notifikasi.',
          actionLabel: 'Lihat lamaran',
          onAction: () =>
              context.pushReplacement(Routes.applicationDetail(sent)),
        ),
      );
    }
    final async = ref.watch(applyContextProvider(widget.listingId));
    final t = context.tokens;
    return AppScaffold(
      title: 'Lamar pekerjaan',
      glow: true,
      body: AsyncBody<ApplyContext>(
        value: async,
        onRetry: () => ref.invalidate(applyContextProvider(widget.listingId)),
        skeleton: const DetailSkeleton(),
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
              AppCard(
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.primaryContainer,
                          borderRadius: AppRadius.brMd,
                        ),
                        child: SizedBox.square(
                          dimension: 48,
                          child: Icon(
                            categoryIcon(l.category),
                            color: t.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.title, style: context.text.h3),
                          Text(
                            '${l.city} · ${budgetRange(l)}',
                            style: context.text.bodySm.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s20),
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
                prefixIcon: LucideIcons.messageSquare,
                controller: _message,
                maxLines: 4,
                maxLength: 500,
                showCounter: true,
                errorText: _err('message'),
                onChanged: (_) => _changed('message'),
              ),
              const SizedBox(height: AppSpace.s16),
              AppTextField(
                key: K.applyRate,
                label:
                    'Tarif yang Anda usulkan per ${l.unit.label.toLowerCase()}',
                prefixText: 'Rp',
                controller: _rate,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _err('proposed_rate'),
                helper: 'Budget pencari ${budgetRange(l)}',
                onChanged: (_) => _changed('proposed_rate'),
              ),
              // Daftar pertanyaan bisa menyusut setelah reload karena konflik; jangan baca di luar batas.
              for (
                var i = 0;
                i < _answers.length && i < l.screeningQuestions.length;
                i++
              ) ...[
                const SizedBox(height: AppSpace.s16),
                AppTextField(
                  label: l.screeningQuestions[i],
                  prefixIcon: LucideIcons.circleHelp,
                  controller: _answers[i],
                  maxLines: 2,
                  maxLength: 200,
                  showCounter: true,
                  errorText: _err('answer_$i'),
                  onChanged: (_) => _changed('answer_$i'),
                ),
              ],
              if (l.requireSkck) ...[
                const SizedBox(height: AppSpace.s20),
                Text('Dokumen', style: context.text.h3),
                const SizedBox(height: AppSpace.s8),
                _SkckUpload(listingId: l.id),
              ],
              const SizedBox(height: AppSpace.s24),
              AppButton(
                key: K.applySubmit,
                label: 'Kirim lamaran',
                icon: LucideIcons.send,
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

/// Area dokumen gaya unggah: status SKCK; ketuk untuk membuka alur verifikasi.
class _SkckUpload extends ConsumerWidget {
  const _SkckUpload({required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final status =
        ref.watch(mySkckStatusProvider).value ?? VerificationStatus.none;
    final ok = status.isVerified;
    final pending = status == VerificationStatus.pending;
    final (title, sub, tone) = ok
        ? ('SKCK terverifikasi', 'Dokumen siap dilampirkan', StatusTone.success)
        : pending
        ? (
            'SKCK sedang diperiksa',
            'Ketuk untuk melihat status',
            StatusTone.info,
          )
        : (
            'Unggah SKCK',
            'Unggah sekali, bisa dipakai untuk lamaran lain',
            StatusTone.warning,
          );
    return Material(
      color: tone.bg(t),
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: ok
            ? null
            : () => context.push('${Routes.skck}?listing=$listingId'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: tone.fg(t).withValues(alpha: .5)),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  ok ? LucideIcons.fileCheck : LucideIcons.upload,
                  color: tone.fg(t),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.label),
                    Text(sub, style: context.text.bodySm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String budgetRange(Listing l) =>
    '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)}';
