import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/time.dart';

enum PeriodUnit {
  daily,
  weekly,
  monthly,
  unknown;

  static PeriodUnit from(String? s) => enumFromWire(values, s, unknown);

  String get label => switch (this) {
    daily => 'Harian',
    weekly => 'Mingguan',
    monthly => 'Bulanan',
    unknown => '-',
  };

  /// Durasi satu periode untuk jadwal (bulan = 30 hari, cukup untuk mock/tampilan).
  Duration get duration => switch (this) {
    daily => const Duration(days: 1),
    weekly => const Duration(days: 7),
    _ => const Duration(days: 30),
  };
}

class Paged<T> {
  const Paged(this.items, {this.nextCursor});
  final List<T> items;
  final String? nextCursor;
  bool get hasMore => nextCursor != null;
}

/// Tagihan Xendit dari server. `url` hanya boleh dibuka bila [isAllowedInvoiceUrl].
class Invoice {
  const Invoice({
    required this.id,
    required this.url,
    required this.amount,
    this.expiresAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
    id: j['id'] as String,
    url: j['invoice_url'] as String,
    amount: j['amount'] as int,
    expiresAt: j['expires_at'] == null
        ? null
        : parseApiTime(j['expires_at'] as String),
  );

  final String id;
  final String url;
  final int amount;
  final DateTime? expiresAt;
}
