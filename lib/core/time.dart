import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const _wibOffset = Duration(hours: 7);

/// Panggil sekali di main() dan di setUpAll() test.
Future<void> initLocale() => initializeDateFormatting('id_ID');

DateTime parseApiTime(String s) => DateTime.parse(s).toUtc();

String toApiTime(DateTime t) => t.toUtc().toIso8601String();

/// Jam dinding WIB (nilainya UTC-flag hanya untuk format; jangan kirim ke API).
DateTime toWib(DateTime t) => t.toUtc().add(_wibOffset);

/// Kebalikan [toWib]: tanggal+jam WIB dari picker -> instan UTC.
DateTime fromWib(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime.utc(y, m, d, h, min).subtract(_wibOffset);

String formatDate(DateTime t) =>
    DateFormat('d MMM y', 'id_ID').format(toWib(t));

String formatTime(DateTime t) => DateFormat('HH.mm', 'id_ID').format(toWib(t));

/// "10 Okt 2026, 14.30 WIB"
String formatDateTime(DateTime t) => '${formatDate(t)}, ${formatTime(t)} WIB';
