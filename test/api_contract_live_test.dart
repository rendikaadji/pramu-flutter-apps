// Uji kontrak terhadap backend pramu-laravel-web yang benar-benar jalan (bukan mock).
// Dilewati secara default. Dijalankan job CI `contract`, atau lokal setelah backend jalan:
//   flutter test test/api_contract_live_test.dart \
//     --dart-define=LIVE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
// Kasus kontrak per endpoint ditambahkan bersama modulnya (Docs/18 §1, Docs/15 §3.3).
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';

import 'helpers/memory_token_store.dart';

const _live = bool.fromEnvironment('LIVE_API');

void main() {
  test(
    'galat API memakai amplop {error: {code, message, fields}} dengan kode PRD §24',
    () async {
      final api = ApiClient(
        tokens: MemoryTokenStore(),
        deviceId: 'contract',
        onUnauthorized: () {},
      );
      await expectLater(
        api.get('/tidak-ada'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 404)
              .having((e) => e.code, 'code', 'NOT_FOUND'),
        ),
      );
    },
    skip: _live ? false : 'butuh backend: --dart-define=LIVE_API=true',
  );
}
