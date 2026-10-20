import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

import 'harness.dart';

class _Host extends StatefulWidget {
  const _Host(this.error, this.onConflict);
  final ApiException error;
  final VoidCallback onConflict;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with ApiActionMixin {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () =>
            act(() async => throw widget.error, onConflict: widget.onConflict),
        child: const Text('Aksi'),
      ),
      if (actionError != null) ActionErrorBox(error: actionError!),
    ],
  );
}

ApiException conflict409(String code, String message) =>
    ApiException(status: 409, code: code, message: message);

void main() {
  testWidgets('409 basi: dialog "Data sudah berubah" lalu onConflict', (
    tester,
  ) async {
    var reloaded = 0;
    await tester.pumpWidget(
      host(
        _Host(
          conflict409('BOOKING_INVALID_STATE', 'Status berubah.'),
          () => reloaded++,
        ),
      ),
    );
    await tester.tap(find.text('Aksi'));
    await tester.pumpAndSettle();
    expect(find.text('Data sudah berubah'), findsOneWidget);
    await tester.tap(find.text('Muat ulang'));
    await tester.pumpAndSettle();
    expect(reloaded, 1);
  });

  for (final code in [
    'PAYMENT_BUSY',
    'BANK_ACCOUNT_RECENTLY_CHANGED',
    'IDEMPOTENCY_KEY_REUSED',
  ]) {
    testWidgets('409 $code: pesan server tampil, tanpa dialog muat ulang', (
      tester,
    ) async {
      var reloaded = 0;
      await tester.pumpWidget(
        host(
          _Host(
            conflict409(code, 'Pesan dari server untuk $code.'),
            () => reloaded++,
          ),
        ),
      );
      await tester.tap(find.text('Aksi'));
      await tester.pumpAndSettle();
      expect(find.text('Data sudah berubah'), findsNothing);
      expect(
        find.textContaining('Pesan dari server untuk $code.'),
        findsOneWidget,
      );
      expect(reloaded, 0);
    });
  }

  testWidgets('502 PAYMENT_GATEWAY_FAILED: pesan server tampil', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        _Host(
          ApiException(
            status: 502,
            code: 'PAYMENT_GATEWAY_FAILED',
            message: 'Gateway pembayaran sedang bermasalah.',
          ),
          () {},
        ),
      ),
    );
    await tester.tap(find.text('Aksi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gateway pembayaran'), findsOneWidget);
  });
}
