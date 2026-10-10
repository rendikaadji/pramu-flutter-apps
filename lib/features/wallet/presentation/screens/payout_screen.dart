import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/platform/secure_screen.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/wallet/data/wallet_providers.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:pramu_apps/features/wallet/presentation/state/wallet_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/money_hero_card.dart';

/// M-81 Tarik dana. Idempotency-Key per niat: sama saat retry, baru bila nominal diubah.
class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _State();
}

class _State extends ConsumerState<PayoutScreen> with ApiActionMixin {
  final _amount = TextEditingController();
  String _key = newIdempotencyKey();
  String? _localError;
  WalletTx? _result;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(Wallet w, BankAccount bank) async {
    final v = parseRupiah(_amount.text);
    if (v == null || v <= 0) {
      setState(() => _localError = 'Isi nominal yang ingin ditarik.');
      return;
    }
    if (v > w.balance) {
      setState(() => _localError = 'Nominal melebihi saldo yang bisa ditarik.');
      return;
    }
    setState(() => _localError = null);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Tarik ${formatRupiah(v)}?',
      message:
          'Dana dikirim ke ${bank.bank} ${bank.maskedNumber} '
          'a.n. ${bank.holderName}. Pastikan rekeningnya sudah benar.',
      confirmLabel: 'Tarik dana',
    );
    if (!ok || !mounted) return;
    WalletTx? tx;
    final done = await act(() async {
      try {
        tx = await ref
            .read(walletRepositoryProvider)
            .requestPayout(v, idempotencyKey: _key);
      } on ApiException catch (e) {
        if (!e.isNetwork && e.status < 500) _key = newIdempotencyKey();
        rethrow;
      }
    }, onConflict: () => ref.invalidate(walletProvider));
    if (!mounted || !done) return;
    ref.invalidate(walletProvider);
    ref.invalidate(walletTxProvider);
    setState(() => _result = tx);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final bank = ref.watch(bankAccountProvider);
    return SecureScreenGuard(
      child: AppScaffold(
        title: 'Tarik dana',
        body: _result != null
            ? _Result(tx: _result!)
            : AsyncBody<Wallet>(
                value: wallet,
                onRetry: () => ref.invalidate(walletProvider),
                skeleton: const DetailSkeleton(),
                data: (context, w) => bank.when(
                  loading: () =>
                      const SingleChildScrollView(child: DetailSkeleton()),
                  error: (e, _) => ApiErrorView(
                    error: asApiException(e),
                    onRetry: () => ref.invalidate(bankAccountProvider),
                  ),
                  data: (b) => _form(context, w, b),
                ),
              ),
      ),
    );
  }

  Widget _form(BuildContext context, Wallet w, BankAccount? b) {
    final t = context.tokens;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoneyHeroCard(
            label: 'Saldo bisa ditarik',
            amount: formatRupiah(w.balance),
          ),
          const SizedBox(height: AppSpace.s16),
          if (b == null || actionError?.code == 'BANK_ACCOUNT_REQUIRED')
            EmptyBank(
              onTap: () async {
                await context.push(Routes.bank);
                ref.invalidate(bankAccountProvider);
              },
            )
          else ...[
            ListTileCard(
              children: [
                MergeSemantics(
                  child: SettingsRow(
                    icon: LucideIcons.landmark,
                    title: '${b.bank} ${b.maskedNumber}',
                    subtitle: 'Rekening tujuan · ${b.holderName}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            if (actionError != null) ActionErrorBox(error: actionError!),
            AppTextField(
              key: K.payoutAmount,
              controller: _amount,
              label: 'Nominal penarikan',
              prefixText: 'Rp',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              errorText: _localError ?? fieldError('amount'),
              onChanged: (_) {
                _key = newIdempotencyKey();
                if (_localError != null || actionError != null) {
                  setState(() {
                    _localError = null;
                    clearActionError();
                  });
                }
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: K.payoutAll,
                onPressed: w.balance <= 0
                    ? null
                    : () {
                        _amount.text = '${w.balance}';
                        _key = newIdempotencyKey();
                        setState(() => _localError = null);
                      },
                child: const Text('Tarik semua saldo'),
              ),
            ),
            Text(
              'Penarikan melewati tiga tahap: antre, diproses, lalu berhasil.',
              style: context.text.caption.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              key: K.payoutSubmit,
              label: 'Tarik dana',
              large: true,
              loading: busy,
              onPressed: canAct ? () => _submit(w, b) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.tx});
  final WalletTx tx;

  @override
  Widget build(BuildContext context) {
    final s = tx.payoutStatus ?? PayoutStatus.queued;
    return Center(
      child: SingleChildScrollView(
        child: Semantics(
          key: K.payoutResult,
          liveRegion: true,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessIllustration(size: 160),
              const SizedBox(height: AppSpace.s16),
              Text('Penarikan sudah diajukan', style: context.text.h2),
              const SizedBox(height: AppSpace.s8),
              MoneyText(formatRupiah(tx.amount), size: MoneySize.hero),
              const SizedBox(height: AppSpace.s8),
              StatusChip.of(StatusDomain.payout, wire(s)),
              const SizedBox(height: AppSpace.s24),
              AppButton(
                label: 'Lihat riwayat dana',
                onPressed: () => context.pushReplacement(Routes.walletHistory),
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Selesai',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
