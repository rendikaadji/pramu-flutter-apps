import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Satu baris riwayat: masuk (+) atau penarikan (-) + status payout.
class WalletTxTile extends StatelessWidget {
  const WalletTxTile({super.key, required this.tx, this.onRetry});
  final WalletTx tx;

  /// Hanya untuk penarikan gagal.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final incoming = tx.type == WalletTxType.earning;
    final amount = '${incoming ? '+' : '-'}${formatRupiah(tx.amount)}';
    final s = tx.payoutStatus;
    final failed = s == PayoutStatus.failed;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s16,
        vertical: AppSpace.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '${tx.title}, ${formatDate(tx.createdAt)}, $amount'
                '${s == null ? '' : ', ${s.label}'}',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: incoming ? t.successContainer : t.primaryContainer,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Icon(
                        incoming
                            ? LucideIcons.arrowDownLeft
                            : LucideIcons.arrowUpRight,
                        size: 20,
                        color: incoming ? t.success : t.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: context.text.body),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        formatDateTime(tx.createdAt),
                        style: context.text.bodySm,
                      ),
                      if (s != null) ...[
                        const SizedBox(height: AppSpace.s4),
                        StatusChip.of(StatusDomain.payout, wire(s)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                MoneyText(
                  amount,
                  color: incoming && !failed ? t.success : t.textPrimary,
                ),
              ],
            ),
          ),
          if (failed) ...[
            const SizedBox(height: AppSpace.s8),
            Text(
              'Penarikan gagal. Saldo Anda sudah dikembalikan. '
              'Periksa nomor rekening lalu coba lagi.',
              style: context.text.bodySm,
            ),
            if (onRetry != null)
              AppButton(
                label: 'Coba lagi',
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: onRetry,
              ),
          ],
        ],
      ),
    );
  }
}
