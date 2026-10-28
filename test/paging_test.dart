import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/listing/presentation/state/paged_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/memory_token_store.dart';

class _Numbers extends PagedNotifier<int, int> {
  int fetches = 0;
  bool failMore = true;

  @override
  int get emptyFilter => 0;

  @override
  Future<Paged<int>> fetch(int filter, String? cursor) async {
    fetches++;
    if (cursor != null && failMore) {
      throw ApiException(status: 0, code: 'NETWORK', message: 'Offline');
    }
    return Paged(const [1, 2], nextCursor: cursor == null ? 'c1' : null);
  }
}

final _numbers = NotifierProvider<_Numbers, PagedState<int>>(_Numbers.new);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Paging: loadMore gagal tidak mengulang request sampai retry eksplisit',
    () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(_numbers, (_, _) {});
      while (c.read(sessionProvider).status == SessionStatus.booting ||
          sub.read().loading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final n = c.read(_numbers.notifier);
      expect(sub.read().items, [1, 2]);

      await n.loadMore(); // gagal
      expect(sub.read().error, isNotNull);
      final after = n.fetches;
      await n.loadMore();
      await n.loadMore();
      expect(
        n.fetches,
        after,
        reason: 'scroll berikutnya tidak memicu request',
      );

      n.failMore = false;
      await n.loadMore(retry: true);
      expect(n.fetches, after + 1);
      expect(sub.read().items, [1, 2, 1, 2]);
      expect(sub.read().error, isNull);
    },
  );
}
