import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/chat/presentation/state/chat_state.dart';
import 'package:pramu_apps/features/home/presentation/state/home_state.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/wallet/presentation/state/wallet_state.dart';
import 'package:pramu_apps/shared/flow_refresh.dart';

void main() {
  test('invalidateFlow tanpa opsi hanya menyegarkan inti alur', () {
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
    expect(hit, isNot(contains(listingBrowseProvider)));
    expect(hit, isNot(contains(conversationsProvider)));
    expect(hit, isNot(contains(walletProvider)));
  });

  test('opsi browse/chat/wallet menambah provider yang sesuai saja', () {
    final hit = <Object>[];
    invalidateFlow(hit.add, wallet: true);
    expect(hit, contains(walletProvider));
    expect(hit, isNot(contains(listingBrowseProvider)));
    final all = <Object>[];
    invalidateFlow(all.add, browse: true, chat: true, wallet: true);
    expect(all.toSet(), flowProviders.toSet());
  });
}
