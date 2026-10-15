import 'package:pramu_apps/core/router/routes.dart';

/// Rute M-95 dengan konteks (semua ULID). Dipakai chat, kontrak, dan pembayaran.
String reportNewPath({
  String? booking,
  String? period,
  String? conversation,
  String? user,
}) {
  final q = {
    'booking': ?booking,
    'period': ?period,
    'conversation': ?conversation,
    'user': ?user,
  };
  return q.isEmpty
      ? Routes.reportNew
      : Uri(path: Routes.reportNew, queryParameters: q).toString();
}
