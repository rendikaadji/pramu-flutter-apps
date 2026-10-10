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
import 'package:pramu_apps/shared/app_ui/rate_text.dart';

/// M-37 Detail pelamar (pencari): kartu kepercayaan + keputusan.
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
    if (done) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(applicantDetailProvider(widget.id));
    return AppScaffold(
      title: 'Detail pelamar',
      body: AsyncBody<ApplicantDetail>(
        value: async,
        onRetry: _reload,
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

  List<Widget> _children(BuildContext context, ApplicantDetail d) {
    final app = d.application;
    final a = app.assistant;
    final t = context.tokens;
    final actions = app.status.allowedActions(Role.seeker);
    final skip = d.listing.skipInterview;
    final acceptable =
        actions.contains(ApplicationAction.accept) &&
        (app.status != ApplicationStatus.shortlisted || skip);
    return [
      if (actionError != null) ActionErrorBox(error: actionError!),
      Row(
        children: [
          AvatarImage(name: a.name, url: a.photoUrl, size: 64),
          const SizedBox(width: AppSpace.s12),
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
      const SizedBox(height: AppSpace.s8),
      const SectionHeader('Kepercayaan'),
      const SizedBox(height: AppSpace.s8),
      TrustCard(
        seal: a.verified ? SealState.verified : SealState.pending,
        skckVerified: app.skckVerified,
        rating: a.ratingCount > 0 ? a.ratingAvg : null,
        reviewCount: a.ratingCount,
        completedJobs: d.profile?.completedJobs ?? 0,
      ),
      const SizedBox(height: AppSpace.s16),
      const SectionHeader('Lamaran'),
      const SizedBox(height: AppSpace.s8),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lamaran untuk', style: context.text.caption),
            Text(app.listingTitle, style: context.text.h3),
            const SizedBox(height: AppSpace.s12),
            Text('Tarif usulan', style: context.text.caption),
            RateText(
              formatRupiah(app.proposedRate),
              unit: d.listing.unit.label.toLowerCase(),
            ),
            const SizedBox(height: AppSpace.s12),
            Text('Pesan', style: context.text.caption),
            Text(app.message, style: context.text.body),
            Text(
              'Dilamar ${formatDate(app.createdAt)}',
              style: context.text.bodySm.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
      if (d.listing.screeningQuestions.isNotEmpty) ...[
        const SizedBox(height: AppSpace.s16),
        const SectionHeader('Jawaban screening'),
        const SizedBox(height: AppSpace.s8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < d.listing.screeningQuestions.length; i++) ...[
                Text(
                  d.listing.screeningQuestions[i],
                  style: context.text.label,
                ),
                Text(
                  i < app.answers.length ? app.answers[i] : '-',
                  style: context.text.body,
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpace.s24),
      const SectionHeader('Keputusan'),
      const SizedBox(height: AppSpace.s8),
      if (actions.contains(ApplicationAction.shortlist))
        _gap(
          AppButton(
            key: K.applicationShortlist,
            label: 'Masukkan daftar pendek',
            icon: LucideIcons.bookmarkPlus,
            loading: busy,
            onPressed: canAct ? () => _do(ApplicationAction.shortlist) : null,
          ),
        ),
      if (actions.contains(ApplicationAction.proposeInterview))
        _gap(
          AppButton(
            key: K.interviewPropose,
            label: 'Ajukan wawancara',
            icon: LucideIcons.video,
            variant: actions.contains(ApplicationAction.shortlist)
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            onPressed: () => context
                .push(Routes.interviewPropose(app.id))
                .then((_) => _reload()),
          ),
        ),
      if (acceptable)
        _gap(
          AppButton(
            key: K.applicationAccept,
            label: app.status == ApplicationStatus.shortlisted
                ? 'Lewati wawancara & terima'
                : 'Terima pelamar',
            icon: LucideIcons.userCheck,
            variant: app.status == ApplicationStatus.shortlisted
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            loading: busy,
            onPressed: canAct
                ? () => _do(
                    ApplicationAction.accept,
                    title: 'Terima pelamar ini?',
                    message:
                        'Anda akan lanjut menyusun kesepakatan dengan ${a.name}.',
                    confirmLabel: 'Terima pelamar',
                  )
                : null,
          ),
        ),
      if (actions.contains(ApplicationAction.proposeAgreement))
        _gap(
          AppButton(
            key: K.applicationAgreement,
            label: app.agreementId == null
                ? 'Susun kesepakatan'
                : 'Lihat kesepakatan',
            onPressed: () => context.push(
              app.agreementId == null
                  ? Routes.agreementNew(app.id)
                  : Routes.agreementReview(app.agreementId!),
            ),
          ),
        ),
      if (app.interviewId != null)
        _gap(
          AppButton(
            label: 'Lihat wawancara',
            icon: LucideIcons.calendar,
            variant: AppButtonVariant.secondary,
            onPressed: () => context
                .push(Routes.interviewDetail(app.interviewId!))
                .then((_) => _reload()),
          ),
        ),
      if (app.conversationId != null)
        _gap(
          AppButton(
            key: K.applicationChat,
            label: 'Buka chat',
            icon: LucideIcons.messageCircle,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(Routes.chatRoom(app.conversationId!)),
          ),
        ),
      if (actions.contains(ApplicationAction.reject))
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.s8),
          child: _RejectButton(
            key: K.applicationReject,
            loading: busy,
            onPressed: canAct
                ? () => _do(
                    ApplicationAction.reject,
                    title: 'Tolak pelamar ini?',
                    message: 'Pelamar akan diberi tahu bahwa tidak dipilih.',
                    confirmLabel: 'Tolak',
                    destructive: true,
                  )
                : null,
          ),
        ),
    ];
  }

  Widget _gap(Widget w) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s12),
    child: w,
  );
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
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: t.danger,
                semanticsLabel: 'Tolak, sedang diproses',
              ),
            )
          : const Icon(LucideIcons.circleX, size: 20),
      label: const Text('Tolak'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpace.tap),
        foregroundColor: t.danger,
        side: BorderSide(color: t.danger.withValues(alpha: .6)),
      ),
    );
  }
}
