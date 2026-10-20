import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/env.dart';

void main() {
  void check({
    bool release = true,
    bool mock = false,
    String url = 'https://api.pramu.id/api/v1',
  }) => Env.checkRelease(release: release, mock: mock, apiBaseUrl: url);

  test('build rilis dengan konfigurasi benar lolos', () {
    check();
  });

  test('build rilis menolak mock', () {
    expect(() => check(mock: true), throwsStateError);
  });

  test('build rilis menolak API_BASE_URL placeholder .example', () {
    expect(
      () => check(url: 'https://api.pramu.example/api/v1'),
      throwsStateError,
    );
  });

  test('build non-rilis tidak diperiksa', () {
    check(release: false, mock: true, url: 'https://api.pramu.example/api/v1');
  });
}
