import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/interview/presentation/state/interview_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-53 Catatan & skor wawancara. Privat: hanya pencari; asisten tidak punya UI ini.
class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<EvaluationScreen> createState() => _State();
}

class _State extends ConsumerState<EvaluationScreen> with ApiActionMixin {
  final _note = TextEditingController();
  final _score = <String, int>{
    'communication': 0,
    'politeness': 0,
    'reliability': 0,
  };
  bool _prefilled = false;
  String? _localError;

  static const _labels = {
    'communication': 'Komunikasi',
    'politeness': 'Kesopanan',
    'reliability': 'Keandalan',
  };

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _prefill(InterviewEvaluation? e) {
    if (_prefilled || e == null) return;
    _prefilled = true;
    _score['communication'] = e.communication;
    _score['politeness'] = e.politeness;
    _score['reliability'] = e.reliability;
    _note.text = e.note ?? '';
  }

  Future<void> _save() async {
    if (_score.values.any((v) => v < 1)) {
      setState(
        () => _localError = 'Beri bintang 1 sampai 5 untuk setiap penilaian.',
      );
      return;
    }
    final ok = await act(
      () => ref
          .read(interviewRepositoryProvider)
          .evaluate(
            widget.id,
            InterviewEvaluation(
              communication: _score['communication']!,
              politeness: _score['politeness']!,
              reliability: _score['reliability']!,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            ),
          ),
      onConflict: () => ref.invalidate(interviewContextProvider(widget.id)),
    );
    if (!ok || !mounted) return;
    ref.invalidate(interviewContextProvider(widget.id));
    ref.invalidate(evaluationProvider(widget.id));
    AppSnack.show(context, 'Catatan sudah tersimpan.', success: true);
    popOrGo(context, Routes.seekerHome);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(interviewContextProvider(widget.id));
    final saved = ref.watch(evaluationProvider(widget.id));
    _prefill(saved.value);
    return AppScaffold(
      title: 'Catatan wawancara',
      body: AsyncBody<InterviewContext>(
        value: async,
        onRetry: () => ref.invalidate(interviewContextProvider(widget.id)),
        skeleton: const DetailSkeleton(),
        data: (ctx, c) {
          if (!c.isSeeker) {
            return const EmptyState(
              icon: LucideIcons.lock,
              title: 'Catatan ini khusus pencari',
              message: 'Hanya pencari yang dapat mengisi dan melihatnya.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [
              if (actionError != null) ActionErrorBox(error: actionError!),
              const PrivacyNote(
                'Hanya Anda yang dapat melihat catatan ini. Admin dan pelamar tidak.',
              ),
              const SizedBox(height: AppSpace.s16),
              Text(c.otherName, style: ctx.text.h3),
              const SizedBox(height: AppSpace.s12),
              for (final e in _labels.entries) ...[
                Text(e.value, style: ctx.text.label),
                KeyedSubtree(
                  key: K.evalScore(e.key),
                  child: RatingStars(
                    value: _score[e.key]!.toDouble(),
                    onChanged: (n) => setState(() {
                      _score[e.key] = n;
                      _localError = null;
                    }),
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
              if (_localError != null || fieldError('scores') != null)
                FieldErrorText(_localError ?? fieldError('scores')!),
              const SizedBox(height: AppSpace.s8),
              AppTextField(
                key: K.evalNote,
                label: 'Catatan pribadi (opsional)',
                controller: _note,
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: AppSpace.s24),
              AppButton(
                key: K.evalSubmit,
                label: 'Simpan catatan',
                large: true,
                loading: busy,
                onPressed: canAct ? _save : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
