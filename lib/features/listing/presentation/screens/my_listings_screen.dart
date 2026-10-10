import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/listing_card.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-35 Lowongan saya (tab Pencari).
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  void _open(BuildContext context, Listing l) {
    final path = switch (l.status) {
      ListingStatus.draft => '${Routes.listingNew}?draft=${l.id}',
      ListingStatus.awaitingPayment => Routes.listingPay(l.id),
      _ => Routes.listingManage(l.id),
    };
    context.push(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myListingsProvider);
    Future<void> refresh() async {
      ref.invalidate(myListingsProvider);
      await ref.read(myListingsProvider.future).catchError((_) => <Listing>[]);
    }

    return AppScaffold(
      title: 'Lowongan saya',
      glow: true,
      floatingActionButton: FloatingActionButton.extended(
        key: K.listingCreate,
        onPressed: () => context.push(Routes.listingNew),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Buat lowongan'),
      ),
      body: AsyncBody<List<Listing>>(
        value: async,
        onRetry: () => ref.invalidate(myListingsProvider),
        skeleton: const ListSkeleton(kind: SkeletonCardKind.listing),
        data: (ctx, list) => list.isEmpty
            ? EmptyState(
                icon: LucideIcons.clipboardList,
                title: 'Belum ada lowongan',
                message: 'Buat lowongan pertama Anda agar pelamar bisa melihat dan melamar.',
                actionLabel: 'Buat lowongan',
                onAction: () => ctx.push(Routes.listingNew),
              )
            : _Tabbed(list: list, refresh: refresh, open: (l) => _open(ctx, l)),
      ),
    );
  }
}

class _Tabbed extends StatefulWidget {
  const _Tabbed({
    required this.list,
    required this.refresh,
    required this.open,
  });
  final List<Listing> list;
  final Future<void> Function() refresh;
  final void Function(Listing) open;

  @override
  State<_Tabbed> createState() => _TabbedState();
}

class _TabbedState extends State<_Tabbed> {
  int _tab = 0;

  bool _match(Listing l) => switch (_tab) {
    1 => l.status == ListingStatus.open,
    2 =>
      l.status == ListingStatus.draft ||
          l.status == ListingStatus.awaitingPayment,
    3 =>
      l.status == ListingStatus.filled ||
          l.status == ListingStatus.closed ||
          l.status == ListingStatus.expired,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final l in widget.list)
        if (_match(l)) l,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.s8),
        SegmentedTabs(
          labels: const ['Semua', 'Tayang', 'Draf', 'Selesai'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: AppSpace.s12),
        Expanded(
          child: shown.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.clipboardList,
                  title: 'Belum ada lowongan',
                  message: 'Belum ada lowongan di tab ini.',
                  compact: true,
                )
              : RefreshIndicator(
                  onRefresh: widget.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      bottom: AppSpace.s64 + AppSpace.s32,
                    ),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s12),
                    itemBuilder: (_, i) => ListingCard(
                      key: K.listingCard(shown[i].id),
                      listing: shown[i],
                      ownerView: true,
                      onTap: () => widget.open(shown[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
