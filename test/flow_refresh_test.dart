import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/home/presentation/state/home_state.dart';
import 'package:pramu_apps/shared/flow_refresh.dart';

void main() {
  test('invalidateFlow menyegarkan tab kontrak, beranda, lamaran, dompet', () {
    final hit = <Object>[];
    invalidateFlow(hit.add);
    expect(
      hit,
      containsAll([
        bookingsProvider,
        seekerHomeProvider,
        assistantHomeProvider,
      ]),
    );
    expect(hit.length, flowProviders.length);
  });
}
