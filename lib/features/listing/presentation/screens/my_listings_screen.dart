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
      floatingActionButton: FloatingActionButton.extended(
        key: K.listingCreate,
        onPressed: () => context.push(Routes.listingNew),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Buat lowongan'),
      ),
      body: AsyncBody<List<Listing>>(
        value: async,
        onRetry: () => ref.invalidate(myListingsProvider),
        data: (ctx, list) => list.isEmpty
            ? EmptyState(
                icon: LucideIcons.clipboardList,
                title: 'Belum ada lowongan',
                message: 'Buat lowongan pertama Anda untuk menemukan asisten.',
                actionLabel: 'Buat lowongan',
                onAction: () => ctx.push(Routes.listingNew),
              )
            : RefreshIndicator(
                onRefresh: refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: AppSpace.s8,
                    bottom: AppSpace.s64 + AppSpace.s32,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.s12),
                  itemBuilder: (_, i) => ListingCard(
                    key: K.listingCard(list[i].id),
                    listing: list[i],
                    ownerView: true,
                    onTap: () => _open(ctx, list[i]),
                  ),
                ),
              ),
      ),
    );
  }
}
