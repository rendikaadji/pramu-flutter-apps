import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/interview/presentation/state/interview_state.dart';
import 'package:pramu_apps/features/interview/presentation/widgets/slot_editor.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/icon_info_row.dart';
import 'package:pramu_apps/shared/app_ui/url_launch.dart';

String countdownText(DateTime slot, DateTime now) {
  final d = slot.difference(now);
  if (d.isNegative) return 'Sudah dimulai';
  if (d.inMinutes < 60) return 'Dimulai dalam ${d.inMinutes} menit';
  if (d.inHours < 24) return 'Dimulai dalam ${d.inHours} jam';
  return 'Dimulai ${d.inDays} hari lagi';
}

/// Hitung mundur yang berdetak (30 dtk) dan diumumkan sebagai live region.
class _Countdown extends StatefulWidget {
  const _Countdown(this.slot);
  final DateTime slot;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      countdownText(widget.slot, DateTime.now().toUtc()),
      style: context.text.label.copyWith(color: context.tokens.primary),
    ),
  );
}

/// M-52 Detail wawancara: waktu, status, Gabung (tautan tervalidasi), jadwal ulang, batal.
class InterviewDetailScreen extends ConsumerStatefulWidget {
  const InterviewDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<InterviewDetailScreen> createState() => _State();
}

class _State extends ConsumerState<InterviewDetailScreen> with ApiActionMixin {
  String? _joinError;

  void _reload() => ref.invalidate(interviewContextProvider(widget.id));

  Future<void> _join(Interview iv) async {
    final ok = await openMeetingUrl(
      ref.read(urlLauncherProvider),
      iv.meetingUrl,
    );
    if (!ok && mounted) {
      setState(
        () => _joinError =
            'Tautan wawancara tidak dapat dibuka. Hubungi pencari lewat chat.',
      );
    }
  }

  Future<void> _cancel() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Batalkan wawancara?',
      message:
          'Pihak lain akan diberi tahu. Anda bisa menjadwalkan ulang nanti.',
      confirmLabel: 'Batalkan wawancara',
      cancelLabel: 'Kembali',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref.read(interviewRepositoryProvider).cancel(widget.id),
      onConflict: _reload,
    );
    if (done) _reload();
  }

  Future<void> _reschedule() async {
    final ok = await showRescheduleSheet(
      context,
      onSubmit: (s) =>
          ref.read(interviewRepositoryProvider).reschedule(widget.id, s),
    );
    if (ok && mounted) {
      _reload();
      AppSnack.show(context, 'Usulan waktu terkirim', success: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(interviewContextProvider(widget.id));
    return AppScaffold(
      title: 'Detail wawancara',
      body: AsyncBody<InterviewContext>(
        value: async,
        onRetry: _reload,
        data: (ctx, c) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: _children(ctx, c),
          ),
        ),
      ),
    );
  }

  List<Widget> _children(BuildContext context, InterviewContext c) {
    final iv = c.interview;
    final role = c.isSeeker ? Role.seeker : Role.assistant;
    final actions = iv.status.allowedActions(role);
    final slot = iv.confirmedSlot;
    final canJoin =
        actions.contains(InterviewAction.join) &&
        isAllowedMeetingUrl(iv.meetingUrl);
    return [
      if (actionError != null) ActionErrorBox(error: actionError!),
      Text('Wawancara dengan ${c.otherName}', style: context.text.h2),
      const SizedBox(height: AppSpace.s4),
      Text(
        c.application.listingTitle,
        style: context.text.bodySm.copyWith(color: context.tokens.textMuted),
      ),
      const SizedBox(height: AppSpace.s12),
      Align(
        alignment: Alignment.centerLeft,
        child: StatusChip.of(
          StatusDomain.interview,
          wire(iv.status),
          role: c.isSeeker ? AppRole.seeker : AppRole.assistant,
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      AppCard(
        color: iv.status == InterviewStatus.confirmed
            ? context.tokens.primaryContainer
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slot != null) ...[
              Text('Waktu wawancara', style: context.text.caption),
              const SizedBox(height: AppSpace.s8),
              Row(
                children: [
                  Icon(
                    LucideIcons.calendarClock,
                    color: context.tokens.primary,
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Text(formatDateTime(slot), style: context.text.h3),
                  ),
                ],
              ),
              if (iv.status == InterviewStatus.confirmed) ...[
                const SizedBox(height: AppSpace.s12),
                _Countdown(slot),
                const SizedBox(height: AppSpace.s4),
                Text(
                  'Kami kirim pengingat 1 jam sebelum wawancara.',
                  style: context.text.bodySm,
                ),
              ],
            ] else ...[
              Text(
                iv.status == InterviewStatus.proposed
                    ? (c.isSeeker
                          ? 'Menunggu asisten memilih salah satu waktu.'
                          : 'Pilih salah satu waktu yang diajukan.')
                    : 'Jadwal tidak tersedia.',
                style: context.text.body,
              ),
              const SizedBox(height: AppSpace.s12),
              for (final s in iv.slots) ...[
                IconInfoRow(
                  icon: LucideIcons.calendarClock,
                  text: formatDateTime(s),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
            if (iv.note != null && iv.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s12),
              Text('Catatan: ${iv.note}', style: context.text.body),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      if (_joinError != null) ...[
        FieldErrorText(_joinError!),
        const SizedBox(height: AppSpace.s12),
      ],
      if (canJoin) ...[
        AppButton(
          key: K.interviewJoin,
          label: 'Gabung Google Meet',
          icon: LucideIcons.video,
          large: true,
          onPressed: () => _join(iv),
        ),
        const SizedBox(height: AppSpace.s12),
      ],
      if (actions.contains(InterviewAction.confirm))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s12),
          child: AppButton(
            key: K.interviewConfirm,
            label: 'Konfirmasi jadwal',
            onPressed: () => context
                .push(Routes.interviewConfirm(iv.id))
                .then((_) => _reload()),
          ),
        ),
      if (actions.contains(InterviewAction.evaluate))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s12),
          child: AppButton(
            key: K.interviewEvaluate,
            label: 'Catatan & skor wawancara',
            icon: LucideIcons.notebookPen,
            variant: AppButtonVariant.secondary,
            onPressed: () => context
                .push(Routes.interviewEval(iv.id))
                .then((_) => _reload()),
          ),
        ),
      if (actions.contains(InterviewAction.reschedule) &&
          !(role == Role.assistant && iv.status == InterviewStatus.proposed))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s12),
          child: AppButton(
            key: K.interviewReschedule,
            label: 'Jadwal ulang',
            variant: AppButtonVariant.secondary,
            onPressed: canAct ? _reschedule : null,
          ),
        ),
      if (actions.contains(InterviewAction.cancel))
        AppButton(
          key: K.interviewCancel,
          label: 'Batalkan wawancara',
          variant: AppButtonVariant.danger,
          loading: busy,
          onPressed: canAct ? _cancel : null,
        ),
    ];
  }
}
