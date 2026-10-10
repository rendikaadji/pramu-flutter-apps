import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/interview/presentation/state/interview_state.dart';
import 'package:pramu_apps/features/interview/presentation/widgets/slot_editor.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-51 Konfirmasi slot (asisten): pilih satu slot atau usulkan waktu lain.
class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ConfirmScreen> createState() => _State();
}

class _State extends ConsumerState<ConfirmScreen> with ApiActionMixin {
  DateTime? _slot;

  void _reload() => ref.invalidate(interviewContextProvider(widget.id));

  Future<void> _confirm() async {
    final ok = await act(
      () => ref.read(interviewRepositoryProvider).confirm(widget.id, _slot!),
      onConflict: _reload,
    );
    if (!ok || !mounted) return;
    _reload();
    AppSnack.show(context, 'Wawancara dikonfirmasi', success: true);
    context.pushReplacement(Routes.interviewDetail(widget.id));
  }

  Future<void> _reschedule() async {
    final ok = await showRescheduleSheet(
      context,
      onSubmit: (s) =>
          ref.read(interviewRepositoryProvider).reschedule(widget.id, s),
    );
    if (!ok || !mounted) return;
    _reload();
    AppSnack.show(context, 'Usulan waktu terkirim', success: true);
    context.pushReplacement(Routes.interviewDetail(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(interviewContextProvider(widget.id));
    final meetFailed = actionError?.code == 'MEET_CREATE_FAILED';
    return AppScaffold(
      title: 'Konfirmasi wawancara',
      body: AsyncBody<InterviewContext>(
        value: async,
        onRetry: _reload,
        data: (ctx, c) {
          final iv = c.interview;
          if (iv.status != InterviewStatus.proposed || c.isSeeker) {
            return EmptyState(
              icon: LucideIcons.calendarCheck,
              title: iv.status.label,
              message: 'Jadwal ini tidak perlu dikonfirmasi lagi.',
              actionLabel: 'Lihat wawancara',
              onAction: () =>
                  ctx.pushReplacement(Routes.interviewDetail(widget.id)),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [
              if (meetFailed)
                Semantics(
                  liveRegion: true,
                  child: AppCard(
                    color: ctx.tokens.dangerContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tautan wawancara belum dapat dibuat. Lamaran Anda tetap aman. Coba lagi.',
                        ),
                        const SizedBox(height: AppSpace.s12),
                        AppButton(
                          key: K.retry,
                          label: 'Coba lagi',
                          icon: LucideIcons.refreshCw,
                          expand: false,
                          loading: busy,
                          onPressed: canAct ? _confirm : null,
                        ),
                      ],
                    ),
                  ),
                )
              else if (actionError != null)
                ActionErrorBox(error: actionError!),
              if (actionError != null) const SizedBox(height: AppSpace.s16),
              Text(
                'Pilih waktu yang cocok dengan ${c.otherName}',
                style: ctx.text.h3,
              ),
              Text(c.application.listingTitle, style: ctx.text.bodySm),
              if (iv.note != null && iv.note!.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s8),
                Text('Catatan: ${iv.note}', style: ctx.text.body),
              ],
              const SizedBox(height: AppSpace.s12),
              RadioGroup<DateTime>(
                groupValue: _slot,
                onChanged: (v) => setState(() => _slot = v),
                child: Column(
                  children: [
                    for (var i = 0; i < iv.slots.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s8),
                        child: Material(
                          key: K.interviewSlot(i),
                          color: ctx.tokens.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd,
                            side: BorderSide(color: ctx.tokens.borderSubtle),
                          ),
                          child: RadioListTile<DateTime>(
                            value: iv.slots[i],
                            title: Text(formatDateTime(iv.slots[i])),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                key: K.interviewConfirm,
                label: 'Konfirmasi jadwal',
                large: true,
                loading: busy && !meetFailed,
                onPressed: canAct && _slot != null ? _confirm : null,
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                key: K.interviewReschedule,
                label: 'Usulkan waktu lain',
                variant: AppButtonVariant.secondary,
                onPressed: canAct ? _reschedule : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
