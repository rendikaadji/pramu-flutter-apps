import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/wallet/presentation/state/wallet_state.dart';
import 'package:pramu_apps/features/wallet/presentation/widgets/wallet_tx_tile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-83 Riwayat dompet & penarikan.
class WalletHistoryScreen extends ConsumerWidget {
  const WalletHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(walletTxProvider.notifier);
    return AppScaffold(
      title: 'Riwayat dompet',
      body: AsyncBody<TxState>(
        value: ref.watch(walletTxProvider),
        onRetry: () => ref.invalidate(walletTxProvider),
        data: (context, s) => RefreshIndicator(
          onRefresh: n.refresh,
          child: s.items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: AppSpace.s48),
                    EmptyState(
                      title: 'Belum ada riwayat',
                      message: 'Pemasukan dan penarikan Anda muncul di sini.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(
                    top: AppSpace.s8,
                    bottom: AppSpace.s24,
                  ),
                  children: [
                    ListTileCard(
                      children: [
                        for (final tx in s.items)
                          WalletTxTile(
                            tx: tx,
                            onRetry: () => context.push(Routes.payout),
                          ),
                      ],
                    ),
                    if (s.nextCursor != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.s16),
                        child: AppButton(
                          label: 'Muat lebih banyak',
                          variant: AppButtonVariant.secondary,
                          loading: s.loadingMore,
                          onPressed: n.loadMore,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
