import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/features/wallet/domain/wallet_repository.dart';

class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository(this._api);
  final ApiClient _api;

  @override
  Future<Wallet> wallet() async =>
      Wallet.fromJson(await _api.get('/wallet') as Json);

  @override
  Future<Paged<WalletTx>> transactions({String? cursor}) => _api.getPage(
    '/wallet/transactions',
    WalletTx.fromJson,
    query: {'cursor': ?cursor},
  );

  @override
  Future<BankAccount?> bankAccount() async {
    try {
      return BankAccount.fromJson(await _api.get('/me/bank-account') as Json);
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<BankAccount> saveBankAccount({
    required String bank,
    required String number,
    required String holderName,
  }) async => BankAccount.fromJson(
    await _api.put(
      '/me/bank-account',
      data: {'bank': bank, 'number': number, 'holder_name': holderName},
    ) as Json,
  );

  @override
  Future<WalletTx> requestPayout(
    int amount, {
    required String idempotencyKey,
  }) async => WalletTx.fromJson(
    await _api.post(
      '/wallet/payouts',
      data: {'amount': amount},
      options: ApiClient.idempotent(idempotencyKey),
    ) as Json,
  );
}
