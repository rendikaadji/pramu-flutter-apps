import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/wallet/data/wallet_providers.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

/// M-80 / M-81.
final walletProvider = FutureProvider.autoDispose<Wallet>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(walletRepositoryProvider).wallet();
}, retry: noRetry);

/// M-81 / M-82 (null = belum ada rekening).
final bankAccountProvider = FutureProvider.autoDispose<BankAccount?>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(walletRepositoryProvider).bankAccount();
}, retry: noRetry);

class TxState {
  const TxState(this.items, this.nextCursor, {this.loadingMore = false});
  final List<WalletTx> items;
  final String? nextCursor;
  final bool loadingMore;
}

/// M-80 (ringkas) dan M-83 (lengkap): halaman pertama + muat lebih banyak.
class WalletTxNotifier extends AsyncNotifier<TxState> {
  @override
  Future<TxState> build() async {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    final p = await ref.read(walletRepositoryProvider).transactions();
    return TxState(p.items, p.nextCursor);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final p = await ref.read(walletRepositoryProvider).transactions();
      return TxState(p.items, p.nextCursor);
    });
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || cur.nextCursor == null || cur.loadingMore) return;
    state = AsyncData(TxState(cur.items, cur.nextCursor, loadingMore: true));
    try {
      final p = await ref
          .read(walletRepositoryProvider)
          .transactions(cursor: cur.nextCursor);
      state = AsyncData(TxState([...cur.items, ...p.items], p.nextCursor));
    } on Exception {
      state = AsyncData(TxState(cur.items, cur.nextCursor));
    }
  }
}

final walletTxProvider =
    AsyncNotifierProvider.autoDispose<WalletTxNotifier, TxState>(
      WalletTxNotifier.new,
      retry: noRetry,
    );
