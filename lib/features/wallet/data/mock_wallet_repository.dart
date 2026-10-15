import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/features/wallet/domain/wallet_repository.dart';

const kMockPayoutMin = 10000;
const kMockPayoutFailAmount =
    99999; // nominal ini -> payout berakhir `failed` (saldo kembali)

/// Payout: `queued` -> `processing` -> `success` (tiap MockBackend.stepDelay), nominal 99.999 -> `failed`.
class MockWalletRepository implements WalletRepository {
  MockWalletRepository(this._b);
  final MockBackend _b;

  void _advance(String uid) {
    final list = _b.walletTx[uid] ?? [];
    for (var i = 0; i < list.length; i++) {
      final tx = list[i];
      final s = tx.payoutStatus;
      if (tx.type != WalletTxType.payout || s == null || s.isFinal) continue;
      final elapsed = _b.now().difference(_b.payoutStart[tx.id]!);
      if (elapsed >= _b.stepDelay * 2) {
        final fail = tx.amount == kMockPayoutFailAmount;
        list[i] = tx.copyWith(
          payoutStatus: fail ? PayoutStatus.failed : PayoutStatus.success,
        );
        if (fail) _b.balances[uid] = (_b.balances[uid] ?? 0) + tx.amount;
      } else if (elapsed >= _b.stepDelay) {
        list[i] = tx.copyWith(payoutStatus: PayoutStatus.processing);
      }
    }
  }

  @override
  Future<Wallet> wallet() => _b.run(() {
    final uid = _b.me.id;
    _advance(uid);
    var held = 0;
    for (final b in _b.bookings.values.where((b) => b.assistant.id == uid)) {
      for (final pid in _b.bookingPeriods[b.id]!) {
        final p = _b.periods[pid]!;
        if (p.status == PeriodStatus.paid ||
            p.status == PeriodStatus.inProgress ||
            p.status == PeriodStatus.awaitingConfirmation) {
          held += _b.feesFor(p.amount).assistantReceives;
        }
      }
    }
    return Wallet(
      balance: _b.balances[uid] ?? 0,
      held: held,
      hasBankAccount: _b.banks.containsKey(uid),
    );
  });

  @override
  Future<Paged<WalletTx>> transactions({String? cursor}) => _b.run(() {
    final uid = _b.me.id;
    _advance(uid);
    final all = [...?_b.walletTx[uid]]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _b.page(all, cursor);
  });

  BankAccount _dto((String, String, String) b) => BankAccount(
    bank: b.$1,
    maskedNumber: '••••${b.$2.substring(b.$2.length - 4)}',
    holderName: b.$3,
  );

  @override
  Future<BankAccount?> bankAccount() => _b.run(() {
    final b = _b.banks[_b.me.id];
    return b == null ? null : _dto(b);
  });

  @override
  Future<BankAccount> saveBankAccount({
    required String bank,
    required String number,
    required String holderName,
  }) => _b.run(() {
    final uid = _b.me.id;
    final fields = <String, List<String>>{
      if (bank.trim().isEmpty) 'bank': ['Bank wajib diisi'],
      if (!RegExp(r'^\d{8,16}$').hasMatch(number))
        'number': ['Nomor rekening 8 sampai 16 digit'],
      if (holderName.trim().isEmpty)
        'holder_name': ['Nama pemilik wajib diisi'],
    };
    if (fields.isNotEmpty) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', fields);
    }
    return _dto(_b.banks[uid] = (bank.trim(), number, holderName.trim()));
  });

  @override
  Future<WalletTx> requestPayout(
    int amount, {
    required String idempotencyKey,
  }) => _b.run(() {
    final dup = _b.payoutByKey[idempotencyKey];
    if (dup != null) return dup;
    final uid = _b.me.id;
    _b.requireVerified();
    if (!_b.banks.containsKey(uid)) {
      apiFail(409, 'BANK_ACCOUNT_REQUIRED', 'Isi rekening bank dulu.');
    }
    final balance = _b.balances[uid] ?? 0;
    if (amount < kMockPayoutMin || amount > balance) {
      apiFail(422, 'VALIDATION_FAILED', 'Nominal tidak valid.', {
        'amount': [
          amount > balance ? 'Melebihi saldo' : 'Minimal tarik Rp10.000',
        ],
      });
    }
    _b.balances[uid] = balance - amount;
    final tx = WalletTx(
      id: _b.newId(),
      type: WalletTxType.payout,
      amount: amount,
      title: 'Penarikan dana',
      createdAt: _b.now(),
      payoutStatus: PayoutStatus.queued,
    );
    (_b.walletTx[uid] ??= []).insert(0, tx);
    _b.payoutStart[tx.id] = _b.now();
    return _b.payoutByKey[idempotencyKey] = tx;
  });
}
