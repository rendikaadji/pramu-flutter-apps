import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';

enum PayoutStatus {
  queued,
  processing,
  success,
  failed,
  unknown;

  static PayoutStatus from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    queued => 'Antre',
    processing => 'Diproses',
    success => 'Berhasil',
    failed => 'Gagal, saldo dikembalikan',
    unknown => 'Status tidak dikenal',
  };

  bool get isFinal => this == success || this == failed;
}

class Wallet {
  const Wallet({
    required this.balance,
    required this.held,
    required this.hasBankAccount,
  });

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
    balance: j['balance'] as int,
    held: j['held'] as int,
    hasBankAccount: j['has_bank_account'] as bool? ?? false,
  );

  final int balance; // bisa ditarik
  final int held; // dana ditahan menunggu selesai
  final bool hasBankAccount;
}

class BankAccount {
  const BankAccount({
    required this.bank,
    required this.maskedNumber,
    required this.holderName,
  });

  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
    bank: j['bank'] as String,
    maskedNumber: j['masked_number'] as String,
    holderName: j['holder_name'] as String,
  );

  final String bank;
  final String
  maskedNumber; // "••••1234"; nomor penuh tidak pernah dikembalikan
  final String holderName;
}

enum WalletTxType { earning, payout, unknown }

class WalletTx {
  const WalletTx({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    required this.createdAt,
    this.payoutStatus,
  });

  factory WalletTx.fromJson(Map<String, dynamic> j) => WalletTx(
    id: j['id'] as String,
    type: enumFromWire(WalletTxType.values, j['type'], WalletTxType.unknown),
    amount: j['amount'] as int,
    title: j['title'] as String,
    createdAt: parseApiTime(j['created_at'] as String),
    payoutStatus: j['payout_status'] == null
        ? null
        : PayoutStatus.from(j['payout_status'] as String),
  );

  final String id;
  final WalletTxType type;
  final int amount; // rupiah, positif
  final String title;
  final DateTime createdAt;
  final PayoutStatus? payoutStatus;

  WalletTx copyWith({PayoutStatus? payoutStatus}) => WalletTx(
    id: id,
    type: type,
    amount: amount,
    title: title,
    createdAt: createdAt,
    payoutStatus: payoutStatus ?? this.payoutStatus,
  );
}
