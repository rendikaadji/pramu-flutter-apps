import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';

abstract interface class WalletRepository {
  Future<Wallet> wallet();
  Future<Paged<WalletTx>> transactions({String? cursor});

  /// Null bila belum ada rekening aktif (1 aktif).
  Future<BankAccount?> bankAccount();
  Future<BankAccount> saveBankAccount({
    required String bank,
    required String number,
    required String holderName,
  });

  /// [idempotencyKey] satu per niat tarik. 409 `BANK_ACCOUNT_REQUIRED`; 422 nominal di luar batas.
  Future<WalletTx> requestPayout(int amount, {required String idempotencyKey});
}
