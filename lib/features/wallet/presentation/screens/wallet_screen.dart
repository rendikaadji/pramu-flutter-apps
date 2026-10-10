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
        body: AsyncBody<Wallet>(
          value: ref.watch(walletProvider),
          onRetry: reload,
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
                const SizedBox(height: AppSpace.s16),
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
  Widget build(BuildContext context) => AppCard(
    key: K.walletBankOpen,
    onTap: onTap,
    child: Row(
      children: [
        const Icon(LucideIcons.landmark),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Text(
            'Isi rekening bank dulu untuk menarik dana.',
            style: context.text.body,
          ),
        ),
        const Icon(LucideIcons.chevronRight),
      ],
    ),
  );
}

class _Balance extends StatelessWidget {
  const _Balance({required this.w});
  final Wallet w;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo bisa ditarik', style: context.text.label),
          const SizedBox(height: AppSpace.s4),
          KeyedSubtree(
            key: K.walletBalance,
            child: MoneyText(formatRupiah(w.balance), size: MoneySize.hero),
          ),
          const SizedBox(height: AppSpace.s12),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.shieldCheck,
                  size: 20,
                  color: t.success,
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: Text(
                  'Dana ditahan (menunggu selesai)',
                  style: context.text.bodySm,
                ),
              ),
              MoneyText(formatRupiah(w.held), size: MoneySize.small),
            ],
          ),
        ],
      ),
    );
  }
}

class _Recent extends ConsumerWidget {
  const _Recent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(walletTxProvider);
    return tx.when(
      loading: () => const ListSkeleton(count: 2),
      error: (e, _) => ApiErrorView(
        error: asApiException(e),
        onRetry: () => ref.invalidate(walletTxProvider),
      ),
      data: (s) => s.items.isEmpty
          ? const AppCard(
              child: EmptyState(
                icon: LucideIcons.wallet,
                title: 'Belum ada saldo',
                message: 'Dana masuk setelah periode kerja selesai.',
              ),
            )
          : AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
              child: Column(
                children: [
                  for (final (i, t) in s.items.take(5).indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    WalletTxTile(tx: t),
                  ],
                ],
              ),
            ),
    );
  }
}
