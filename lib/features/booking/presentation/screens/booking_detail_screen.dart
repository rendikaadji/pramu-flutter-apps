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
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/booking/presentation/widgets/booking_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/report_path.dart';

/// M-73 Detail booking: pusat kontrak.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _State();
}

class _State extends ConsumerState<BookingDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _reload();
  }

  void _reload() => ref.invalidate(bookingProvider(widget.bookingId));

  /// Buka rute lalu muat ulang saat kembali (pembatalan/konfirmasi mengubah status).
  Future<void> _go(String path) async {
    await context.push(path);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ref.watch(sessionProvider.select((s) => s.activeRole)) ?? Role.seeker;
    return AppScaffold(
      title: 'Detail kontrak',
      glow: true,
      actions: [
        AppIconButton(
          icon: LucideIcons.refreshCw,
          label: 'Muat ulang',
          onPressed: _reload,
        ),
      ],
      body: AsyncBody<Booking>(
        value: ref.watch(bookingProvider(widget.bookingId)),
        onRetry: _reload,
        data: (context, b) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(bookingProvider(widget.bookingId).future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpace.s24),
            children: _content(context, b, role),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, Booking b, Role role) {
    final t = context.tokens;
    final seeker = role == Role.seeker;
    final other = seeker ? b.assistant : b.seeker;
    final next = b.nextPeriod;
    final frozen =
        b.status == BookingStatus.disputed ||
        b.status == BookingStatus.cancelled ||
        b.status == BookingStatus.completed;
    final actions = next == null || frozen
        ? const <PeriodAction>{}
        : next.status.actionsFor(role);
    final dueBanner = b.pausedUntil;
    return [
      ContractHeader(
        title: b.listingTitle,
        counterpart: other.name,
        status: StatusChip.of(
          StatusDomain.booking,
          wire(b.status),
          role: appRoleOf(role),
        ),
        summary:
            '${formatRupiah(b.rate)} per periode (${b.unit.label}), '
            '${b.periodCount} periode, mulai ${formatDate(b.startDate)}',
      ),
      const SizedBox(height: AppSpace.s16),
      if (b.status == BookingStatus.paused)
        StatusBanner(
          icon: LucideIcons.clock,
          text: dueBanner == null
              ? 'Kontrak dijeda: tagihan belum dibayar.'
              : 'Kontrak dijeda: tagihan belum dibayar. Batas ${formatDate(dueBanner)}.',
        ),
      if (b.status == BookingStatus.disputed)
        const StatusBanner(
          icon: LucideIcons.triangleAlert,
          text: 'Kontrak sedang ditinjau tim kami. Aksi pembayaran dibekukan sementara.',
        ),
      if (b.status == BookingStatus.cancelled)
        const StatusBanner(
          icon: LucideIcons.ban,
          danger: true,
          text: 'Kontrak dibatalkan. Dana mengikuti rincian pembatalan.',
        ),
      if (b.status == BookingStatus.paused ||
          b.status == BookingStatus.disputed ||
          b.status == BookingStatus.cancelled)
        const SizedBox(height: AppSpace.s16),
      if (next != null && !frozen) ...[
        AppCard(
          key: K.periodTile(next.id),
          color: t.roleContainer(appRoleOf(role)),
          borderColor: t.roleColor(appRoleOf(role)).withValues(alpha: .4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Langkah berikutnya · Periode ${next.index}',
                style: context.text.label,
              ),
              const SizedBox(height: AppSpace.s4),
              Text(next.status.labelFor(role), style: context.text.h3),
              const SizedBox(height: AppSpace.s4),
              Text(periodRange(next), style: context.text.bodySm),
              if (actions.contains(PeriodAction.pay)) ...[
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  key: K.bookingPay,
                  label: 'Bayar ${formatRupiah(next.total)}',
                  onPressed: () => _go(Routes.periodPay(next.id)),
                ),
              ],
              if (actions.contains(PeriodAction.confirmComplete)) ...[
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  key: K.bookingConfirmOpen,
                  label: 'Konfirmasi selesai',
                  onPressed: () => _go(Routes.periodConfirm(next.id)),
                ),
              ],
              if (actions.contains(PeriodAction.report)) ...[
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  key: K.bookingReport,
                  label: 'Laporkan masalah',
                  variant: AppButtonVariant.secondary,
                  icon: LucideIcons.flag,
                  onPressed: () =>
                      _go(reportNewPath(booking: b.id, period: next.id)),
                ),
              ],
              if (!seeker && next.status.canDispute) ...[
                const SizedBox(height: AppSpace.s8),
                Text(
                  next.status.canConfirmComplete && next.autoReleaseAt != null
                      ? 'Dana otomatis dicairkan ${formatDateTime(next.autoReleaseAt!)} bila tidak dikonfirmasi.'
                      : 'Dana Anda aman dan dicairkan setelah periode selesai.',
                  style: context.text.bodySm,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
      ],
      const SectionHeader('Rincian biaya'),
      AppCard(child: FeeBreakdown(rows: contractFeeRows(b.fees, role))),
      const SizedBox(height: AppSpace.s16),
      const SectionHeader('Jadwal pembayaran'),
      LedgerTimeline(
        entries: [
          for (final p in b.periods)
            LedgerEntry(
              title: 'Periode ${p.index}',
              label: periodShortLabel(p.status, role),
              tone: periodTone(p.status, role),
              date: periodRange(p),
              amount: formatRupiah(seeker ? p.total : p.amount),
            ),
        ],
      ),
      const SizedBox(height: AppSpace.s16),
      if (b.conversationId != null)
        AppButton(
          key: K.bookingChat,
          label: 'Buka percakapan',
          variant: AppButtonVariant.secondary,
          icon: LucideIcons.messageCircle,
          onPressed: () => context.push(Routes.chatRoom(b.conversationId!)),
        ),
      if (b.status.canRate) ...[
        const SizedBox(height: AppSpace.s8),
        AppButton(
          key: K.bookingRate,
          label: 'Beri penilaian',
          icon: LucideIcons.star,
          onPressed: () => context.push(Routes.rating(b.id)),
        ),
      ],
      if (seeker && b.status.canCancel) ...[
        const SizedBox(height: AppSpace.s8),
        AppButton(
          key: K.bookingCancel,
          label: 'Batalkan kontrak',
          variant: AppButtonVariant.text,
          onPressed: () => _go(Routes.bookingCancel(b.id)),
        ),
      ],
    ];
  }
}
