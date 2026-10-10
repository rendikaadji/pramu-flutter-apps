import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-45 Detail lamaran (asisten). Pencari dialihkan ke M-37.
class ApplicationDetailScreen extends ConsumerStatefulWidget {
  const ApplicationDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ApplicationDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ApplicationDetailScreen>
    with ApiActionMixin {
  void _reload() {
    ref.invalidate(applicationProvider(widget.id));
    ref.invalidate(applicationInterviewProvider(widget.id));
  }

  Future<void> _withdraw() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Tarik lamaran?',
      message: 'Setelah ditarik, Anda tidak dapat melamar ulang lowongan ini.',
      confirmLabel: 'Tarik lamaran',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref
          .read(applicationRepositoryProvider)
          .act(widget.id, ApplicationAction.withdraw),
      onConflict: _reload,
    );
    if (done) {
      ref.invalidate(myApplicationsProvider);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(applicationProvider(widget.id));
    final meId = ref.watch(sessionProvider.select((s) => s.user?.id));
    final app = async.value;
    if (app != null && meId != null && app.seeker.id == meId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(Routes.applicant(app.id));
      });
    }
    return AppScaffold(
      title: 'Detail lamaran',
      body: AsyncBody<Application>(
        value: async,
        onRetry: _reload,
        data: (ctx, a) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: _children(ctx, a),
          ),
        ),
      ),
    );
  }

  Widget _next(BuildContext context, Application a) {
    final iv = ref.watch(applicationInterviewProvider(a.id)).value;
    void go(String path) => context.push(path).then((_) => _reload());
    final (title, message, onTap) = switch (a.status) {
      ApplicationStatus.pending => (
        'Menunggu pencari',
        'Pencari akan memeriksa lamaran Anda.',
        null,
      ),
      ApplicationStatus.shortlisted => (
        'Masuk daftar pendek',
        'Pencari dapat mengajukan jadwal wawancara.',
        null,
      ),
      ApplicationStatus.interviewScheduled =>
        iv != null && iv.status == InterviewStatus.proposed
            ? (
                'Konfirmasi jadwal wawancara',
                'Pilih salah satu waktu yang diajukan pencari.',
                () => go(Routes.interviewConfirm(iv.id)),
              )
            : (
                'Wawancara terjadwal',
                'Lihat waktu dan tautan Google Meet.',
                iv == null ? null : () => go(Routes.interviewDetail(iv.id)),
              ),
      ApplicationStatus.interviewed => (
        'Menunggu keputusan pencari',
        'Wawancara sudah selesai.',
        null,
      ),
      ApplicationStatus.accepted => (
        'Anda diterima',
        'Lanjutkan ke penyusunan kontrak.',
        () => go(
          a.agreementId == null
              ? Routes.agreementNew(a.id)
              : Routes.agreementReview(a.agreementId!),
        ),
      ),
      ApplicationStatus.rejected => (
        'Lamaran belum dipilih',
        'Terima kasih sudah melamar. Coba lowongan lain yang cocok.',
        null,
      ),
      ApplicationStatus.withdrawn => (
        'Lamaran ditarik',
        'Anda sudah menarik lamaran ini.',
        null,
      ),
      ApplicationStatus.unknown => (
        'Status berubah',
        'Muat ulang untuk melihat yang terbaru.',
        null,
      ),
    };
    return NextStepCard(
      title: title,
      message: message,
      role: AppRole.assistant,
      onTap: onTap,
    );
  }

  List<Widget> _children(BuildContext context, Application a) {
    final t = context.tokens;
    final withdrawable = a.status
        .allowedActions(Role.assistant)
        .contains(ApplicationAction.withdraw);
    return [
      if (actionError != null) ActionErrorBox(error: actionError!),
      Text(a.listingTitle, style: context.text.h2),
      const SizedBox(height: AppSpace.s8),
      Wrap(
        spacing: AppSpace.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusChip.of(StatusDomain.application, wire(a.status)),
          Text(
            'Dilamar ${formatDate(a.createdAt)}',
            style: context.text.bodySm.copyWith(color: t.textMuted),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.s16),
      _next(context, a),
      const SizedBox(height: AppSpace.s16),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pencari', style: context.text.caption),
            Text(a.seeker.name, style: context.text.h3),
            const SizedBox(height: AppSpace.s12),
            Text('Tarif yang Anda usulkan', style: context.text.caption),
            MoneyText(formatRupiah(a.proposedRate)),
            const SizedBox(height: AppSpace.s12),
            Text('Pesan Anda', style: context.text.caption),
            Text(a.message, style: context.text.body),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      if (a.conversationId != null &&
          a.status != ApplicationStatus.rejected &&
          a.status != ApplicationStatus.withdrawn) ...[
        AppButton(
          key: K.applicationChat,
          label: 'Buka percakapan',
          icon: LucideIcons.messageCircle,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(Routes.chatRoom(a.conversationId!)),
        ),
        const SizedBox(height: AppSpace.s12),
      ],
      if (withdrawable)
        AppButton(
          key: K.applyWithdraw,
          label: 'Tarik lamaran',
          variant: AppButtonVariant.danger,
          loading: busy,
          onPressed: canAct ? _withdraw : null,
        ),
    ];
  }
}
