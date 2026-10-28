import 'package:pramu_apps/core/router/routes.dart';

/// Rute M-95 dengan konteks (semua ULID). Dipakai chat dan kontrak.
String reportNewPath({String? booking, String? conversation, String? user}) {
  final q = {'booking': ?booking, 'conversation': ?conversation, 'user': ?user};
  return q.isEmpty
      ? Routes.reportNew
      : Uri(path: Routes.reportNew, queryParameters: q).toString();
}
