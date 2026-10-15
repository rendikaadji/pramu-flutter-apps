import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/platform/secure_screen.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/features/wallet/presentation/state/wallet_state.dart';
import 'package:pramu_apps/features/wallet/presentation/widgets/wallet_tx_tile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/money_hero_card.dart';

/// M-80 Dompet (tab root Asisten).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void reload() {
      ref.invalidate(walletProvider);
      ref.invalidate(walletTxProvider);
    }

    return SecureScreenGuard(
      child: AppScaffold(
        title: 'Dompet',
        glow: true,
        body: AsyncBody<Wallet>(
          value: ref.watch(walletProvider),
          onRetry: reload,
          skeleton: const WalletSkeleton(),
          data: (context, w) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.s24),
              children: [
                _Balance(w: w),
                const SizedBox(height: AppSpace.s16),
                if (!w.hasBankAccount) ...[
                  EmptyBank(onTap: () => context.push(Routes.bank)),
                  const SizedBox(height: AppSpace.s16),
                ],
                AppButton(
                  key: K.walletPayoutOpen,
                  label: 'Tarik dana',
                  large: true,
                  icon: LucideIcons.banknote,
                  onPressed: () async {
                    await context.push(Routes.payout);
                    reload();
                  },
                ),
                const SizedBox(height: AppSpace.s24),
                SectionHeader(
                  'Riwayat',
                  actionLabel: 'Lihat semua',
                  onAction: () => context.push(Routes.walletHistory),
                ),
                const _Recent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ajakan mengisi rekening (dipakai juga di M-81).
class EmptyBank extends StatelessWidget {
  const EmptyBank({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTileCard(
    children: [
      SettingsRow(
        key: K.walletBankOpen,
        icon: LucideIcons.landmark,
        title: 'Tambahkan rekening bank untuk menarik dana.',
        onTap: onTap,
      ),
    ],
  );
}

class _Balance extends StatelessWidget {
  const _Balance({required this.w});
  final Wallet w;

  @override
  Widget build(BuildContext context) => MoneyHeroCard(
    label: 'Saldo bisa ditarik',
    amount: formatRupiah(w.balance),
    amountKey: K.walletBalance,
    footerLabel: 'Dana ditahan, menunggu pekerjaan selesai',
    footerAmount: formatRupiah(w.held),
  );
}

class _Recent extends ConsumerWidget {
  const _Recent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(walletTxProvider);
    return tx.when(
      loading: () =>
          const ListSkeleton(count: 3, kind: SkeletonCardKind.transaction),
      error: (e, _) => ApiErrorView(
        error: asApiException(e),
        onRetry: () => ref.invalidate(walletTxProvider),
      ),
      data: (s) => s.items.isEmpty
          ? const EmptyState(
              compact: true,
              title: 'Belum ada saldo',
              message: 'Dana masuk setelah periode kerja selesai.',
            )
          : ListTileCard(
              children: [for (final t in s.items.take(5)) WalletTxTile(tx: t)],
            ),
    );
  }
}
