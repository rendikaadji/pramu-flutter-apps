import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/chip_select.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/listing_card.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/compact_rating.dart';
import 'package:pramu_apps/shared/app_ui/icon_info_row.dart';
import 'package:pramu_apps/shared/app_ui/rate_text.dart';

/// M-36 Detail lowongan (pencari): ringkasan, pelamar, tutup lowongan.
class ListingManageScreen extends ConsumerStatefulWidget {
  const ListingManageScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ListingManageScreen> createState() => _State();
}

class _State extends ConsumerState<ListingManageScreen> with ApiActionMixin {
  ApplicationStatus? _status;

  void _reload() {
    ref.invalidate(listingDetailProvider(widget.id));
    ref.invalidate(listingApplicantsProvider(widget.id));
  }

  Future<void> _close() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Tutup lowongan?',
      message: 'Lowongan tidak tayang lagi. Pelamar yang belum diproses akan kami beri kabar.',
      confirmLabel: 'Tutup lowongan',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref.read(listingRepositoryProvider).close(widget.id),
      onConflict: _reload,
    );
    if (done) {
      ref.invalidate(myListingsProvider);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(listingDetailProvider(widget.id));
    final l = listing.value;
    return AppScaffold(
      title: 'Kelola lowongan',
      actions: [
        if (l != null && l.status.canClose)
          AppIconButton(
            key: K.listingClose,
            icon: LucideIcons.circleX,
            label: 'Tutup lowongan',
            onPressed: canAct ? _close : null,
          ),
      ],
      body: AsyncBody<Listing>(
        value: listing,
        onRetry: _reload,
        data: (ctx, l) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [
              if (actionError != null) ActionErrorBox(error: actionError!),
              _Summary(listing: l),
              const SizedBox(height: AppSpace.s16),
              if (l.status == ListingStatus.filled) ...[
                NextStepCard(
                  title: 'Lowongan sudah terisi',
                  message: 'Lihat kontrak yang sedang berjalan.',
                  onTap: () => ctx.push(Routes.contracts),
                ),
                const SizedBox(height: AppSpace.s16),
              ],
              if (l.status.canPay) ...[
                AppButton(
                  key: K.listingPay,
                  label: 'Bayar dan tayangkan',
                  onPressed: () => ctx.push(Routes.listingPay(l.id)),
                ),
                const SizedBox(height: AppSpace.s16),
              ],
              _Applicants(
                listing: l,
                status: _status,
                onStatus: (s) => setState(() => _status = s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = context.tokens;
    final days = daysLeft(l);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.title, style: context.text.h2),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip.of(StatusDomain.listing, wire(l.status)),
              if (days != null)
                Text(
                  'Sisa $days hari',
                  style: context.text.bodySm.copyWith(color: t.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          RateText(
            '${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)}',
            unit: l.unit.label.toLowerCase(),
          ),
          const SizedBox(height: AppSpace.s12),
          IconInfoRow(
            icon: LucideIcons.briefcase,
            text: '${l.category} · ${l.city}',
          ),
          const SizedBox(height: AppSpace.s8),
          IconInfoRow(
            icon: LucideIcons.calendar,
            text: '${l.periodCount} periode, mulai ${formatDate(l.startDate)}',
          ),
          if (l.requireSkck) ...[
            const SizedBox(height: AppSpace.s8),
            const IconInfoRow(icon: LucideIcons.fileCheck, text: 'Wajib SKCK'),
          ],
          if (l.description.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s12),
            Text(l.description, style: context.text.body),
          ],
        ],
      ),
    );
  }
}

class _Applicants extends ConsumerWidget {
  const _Applicants({
    required this.listing,
    required this.status,
    required this.onStatus,
  });
  final Listing listing;
  final ApplicationStatus? status;
  final ValueChanged<ApplicationStatus?> onStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingApplicantsProvider(listing.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Pelamar'),
        const SizedBox(height: AppSpace.s8),
        if (async.hasValue) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ChipSelect<ApplicationStatus>(
              options: const [
                ApplicationStatus.pending,
                ApplicationStatus.shortlisted,
                ApplicationStatus.interviewScheduled,
                ApplicationStatus.interviewed,
                ApplicationStatus.accepted,
                ApplicationStatus.rejected,
              ],
              labelOf: (s) => s.label,
              selected: status,
              onChanged: onStatus,
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Builder(
            builder: (ctx) {
              final all = async.requireValue;
              final list = status == null
                  ? all
                  : all.where((a) => a.status == status).toList();
              if (list.isEmpty) {
                final until = listing.expiresAt;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
                  child: Text(
                    status != null
                        ? 'Belum ada pelamar dengan status ini.'
                        : 'Belum ada pelamar.${until == null ? '' : ' Lowongan Anda tayang sampai ${formatDate(until)}.'}',
                    style: context.text.body,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: [
                  for (final a in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s12),
                      child: _ApplicantTile(
                        app: a,
                        onReturn: () => ref.invalidate(
                          listingApplicantsProvider(listing.id),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ] else if (async.hasError)
          ApiErrorView(
            error: asApiException(async.error!),
            onRetry: () =>
                ref.invalidate(listingApplicantsProvider(listing.id)),
          )
        else
          const ListSkeleton(count: 2),
      ],
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  const _ApplicantTile({required this.app, required this.onReturn});
  final Application app;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final a = app.assistant;
    return AppCard(
      key: K.applicantCard(app.id),
      onTap: () =>
          context.push(Routes.applicant(app.id)).then((_) => onReturn()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarImage(name: a.name, url: a.photoUrl, size: 48),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: context.text.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.s4),
                Wrap(
                  spacing: AppSpace.s12,
                  runSpacing: AppSpace.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (a.verified) const VerificationSeal(size: SealSize.sm),
                    if (a.ratingCount > 0)
                      CompactRating(value: a.ratingAvg, count: a.ratingCount),
                  ],
                ),
                const SizedBox(height: AppSpace.s8),
                RateText(
                  formatRupiah(app.proposedRate),
                  unit: 'usulan',
                  size: MoneySize.small,
                ),
                const SizedBox(height: AppSpace.s8),
                StatusChip.of(StatusDomain.application, wire(app.status)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
