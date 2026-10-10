import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

/// SATU-satunya tempat format uang. 25000 -> "Rp25.000".
String formatRupiah(int amount) => _idr.format(amount);

/// Input pengguna -> rupiah bulat. Tolak kosong, negatif, dan desimal ("25.000,50").
int? parseRupiah(String input) {
  final s = input.trim();
  if (s.isEmpty || s.contains('-') || RegExp(r',\d*[1-9]').hasMatch(s)) {
    return null;
  }
  final digits = s
      .replaceAll(RegExp(r',0*$'), '')
      .replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}
