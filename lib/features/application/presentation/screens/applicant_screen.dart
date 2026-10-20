import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/pinned_actions_bar.dart';
import 'package:pramu_apps/shared/app_ui/rate_text.dart';
import 'package:pramu_apps/shared/flow_refresh.dart';

/// M-37 Detail pelamar (pencari): rekam jejak + keputusan.
class ApplicantScreen extends ConsumerStatefulWidget {
  const ApplicantScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ApplicantScreen> createState() => _State();
}

class _State extends ConsumerState<ApplicantScreen> with ApiActionMixin {
  void _reload() {
    ref.invalidate(applicantDetailProvider(widget.id));
    ref.invalidate(applicationInterviewProvider(widget.id));
  }

  Future<void> _do(
    ApplicationAction action, {
    String? title,
    String? message,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    if (title != null) {
      final ok = await ConfirmDialog.show(
        context,
        title: title,
        message: message ?? '',
        confirmLabel: confirmLabel ?? 'Ya',
        destructive: destructive,
      );
      if (!ok || !mounted) return;
    }
    final done = await act(
      () => ref.read(applicationRepositoryProvider).act(widget.id, action),
      onConflict: _reload,
    );
    if (done) {
      invalidateFlow(ref.invalidate);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(applicantDetailProvider(widget.id));
    final pinned = async.hasValue ? _pinned(context, async.requireValue) : null;
    return AppScaffold(
      title: 'Detail pelamar',
      bottomNavigationBar: pinned == null || pinned.isEmpty
          ? null
          : PinnedActionsBar(children: pinned),
      body: AsyncBody<ApplicantDetail>(
        value: async,
        onRetry: _reload,
        skeleton: const DetailSkeleton(),
        data: (ctx, d) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: _children(ctx, d),
          ),
        ),
      ),
    );
  }

  /// Keputusan utama menempel di bawah: satu primer, sisanya sekunder.
  List<Widget> _pinned(BuildContext context, ApplicantDetail d) {
    final app = d.application;
    final actions = app.status.allowedActions(Role.seeker);
    final shortlisted = app.status == ApplicationStatus.shortlisted;
    final acceptable =
        actions.contains(ApplicationAction.accept) &&
        (!shortlisted || d.listing.skipInterview);
    final canShortlist = actions.contains(ApplicationAction.shortlist);
    final list = <Widget>[
      if (canShortlist)
        AppButton(
          key: K.applicationShortlist,
          label: 'Masukkan ke daftar pendek',
          icon: LucideIcons.bookmarkPlus,
          loading: busy,
          onPressed: canAct ? () => _do(ApplicationAction.shortlist) : null,
        ),
      if (actions.contains(ApplicationAction.proposeInterview))
        AppButton(
          key: K.interviewPropose,
          label: 'Ajukan wawancara',
          icon: LucideIcons.video,
          variant: canShortlist
              ? AppButtonVariant.secondary
              : AppButtonVariant.primary,
          onPressed: () => context
              .push(Routes.interviewPropose(app.id))
              .then((_) => _reload()),
        ),
      if (acceptable)
        AppButton(
          key: K.applicationAccept,
          label: shortlisted ? 'Terima tanpa wawancara' : 'Terima pelamar',
          icon: LucideIcons.userCheck,
          variant: shortlisted
              ? AppButtonVariant.secondary
              : AppButtonVariant.primary,
          loading: busy,
          onPressed: canAct
              ? () => _do(
                  ApplicationAction.accept,
                  title: 'Terima pelamar ini?',
                  message:
                      'Anda lanjut menyusun kontrak dengan ${app.assistant.name}.',
                  confirmLabel: 'Terima pelamar',
                )
              : null,
        ),
      if (actions.contains(ApplicationAction.proposeAgreement))
        AppButton(
          key: K.applicationAgreement,
          label: app.agreementId == null ? 'Susun kontrak' : 'Lihat kontrak',
          onPressed: () => context.push(
            app.agreementId == null
                ? Routes.agreementNew(app.id)
                : Routes.agreementReview(app.agreementId!),
          ),
        ),
    ];
    return [
      for (var i = 0; i < list.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpace.s8),
        list[i],
      ],
    ];
  }

  List<Widget> _children(BuildContext context, ApplicantDetail d) {
    final app = d.application;
    final a = app.assistant;
    final t = context.tokens;
    final actions = app.status.allowedActions(Role.seeker);
    final questions = d.listing.screeningQuestions;
    return [
      if (actionError != null) ActionErrorBox(error: actionError!),
      AppCard(
        child: Row(
          children: [
            AvatarImage(name: a.name, url: a.photoUrl, size: 64),
            const SizedBox(width: AppSpace.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: context.text.h2),
                  const SizedBox(height: AppSpace.s8),
                  StatusChip.of(StatusDomain.application, wire(app.status)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      const SectionHeader('Rekam jejak'),
      TrustCard(
        seal: a.verified ? SealState.verified : SealState.pending,
        skckVerified: app.skckVerified,
        rating: a.ratingCount > 0 ? a.ratingAvg : null,
        reviewCount: a.ratingCount,
        completedJobs: d.profile?.completedJobs ?? 0,
      ),
      const SizedBox(height: AppSpace.s16),
      const SectionHeader('Lamarannya'),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Melamar untuk', style: context.text.caption),
            Text(app.listingTitle, style: context.text.h3),
            const SizedBox(height: AppSpace.s12),
            Text('Tarif yang diusulkan', style: context.text.caption),
            RateText(
              formatRupiah(app.proposedRate),
              unit: d.listing.unit.label.toLowerCase(),
            ),
            const SizedBox(height: AppSpace.s12),
            Text('Pesan dari pelamar', style: context.text.caption),
            Text(app.message, style: context.text.body),
            const SizedBox(height: AppSpace.s8),
            Text(
              'Dikirim ${formatDate(app.createdAt)}',
              style: context.text.bodySm.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
      if (questions.isNotEmpty) ...[
        const SizedBox(height: AppSpace.s16),
        const SectionHeader('Jawaban atas pertanyaan Anda'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < questions.length; i++) ...[
                Text(questions[i], style: context.text.label),
                Text(
                  i < app.answers.length ? app.answers[i] : '-',
                  style: context.text.body,
                ),
                if (i < questions.length - 1)
                  const SizedBox(height: AppSpace.s12),
              ],
            ],
          ),
        ),
      ],
      if (app.interviewId != null || app.conversationId != null) ...[
        const SizedBox(height: AppSpace.s16),
        ListTileCard(
          children: [
            if (app.interviewId != null)
              SettingsRow(
                icon: LucideIcons.calendar,
                title: 'Lihat wawancara',
                subtitle: 'Jadwal dan tautan Google Meet',
                onTap: () => context
                    .push(Routes.interviewDetail(app.interviewId!))
                    .then((_) => _reload()),
              ),
            if (app.conversationId != null)
              SettingsRow(
                key: K.applicationChat,
                icon: LucideIcons.messageCircle,
                title: 'Buka percakapan',
                subtitle: 'Bertanya sebelum memutuskan',
                onTap: () => context.push(Routes.chatRoom(app.conversationId!)),
              ),
          ],
        ),
      ],
      if (actions.contains(ApplicationAction.reject)) ...[
        const SizedBox(height: AppSpace.s24),
        _RejectButton(
          key: K.applicationReject,
          loading: busy,
          onPressed: canAct
              ? () => _do(
                  ApplicationAction.reject,
                  title: 'Tolak pelamar ini?',
                  message: 'Pelamar akan menerima kabar bahwa lamarannya belum dipilih.',
                  confirmLabel: 'Tolak pelamar',
                  destructive: true,
                )
              : null,
        ),
      ],
    ];
  }
}

/// Tolak = aksi sekunder: outline bahaya, tidak mendominasi tombol utama.
class _RejectButton extends StatelessWidget {
  const _RejectButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.danger,
                semanticsLabel: 'Menolak pelamar, sedang diproses',
              ),
            )
          : const Icon(LucideIcons.circleX, size: 20),
      label: const Text('Tolak pelamar'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpace.tap),
        foregroundColor: t.danger,
        side: BorderSide(color: t.danger.withValues(alpha: .6)),
      ),
    );
  }
}
