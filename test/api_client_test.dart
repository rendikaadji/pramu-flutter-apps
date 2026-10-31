import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/env.dart';

import 'helpers/memory_token_store.dart';

typedef _Handler = ResponseBody Function(RequestOptions o);

/// Adapter tiruan: mencatat tiap permintaan, jawaban dari antrean handler (yang terakhir dipakai berulang).
class _Stub implements HttpClientAdapter {
  _Stub(this.handlers);
  final List<_Handler> handlers;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final i = calls.length <= handlers.length
        ? calls.length - 1
        : handlers.length - 1;
    return handlers[i](options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  int status,
  Object body, {
  Map<String, List<String>>? headers,
}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...?headers,
  },
);

ResponseBody _netError(RequestOptions o) =>
    throw DioException.connectionError(requestOptions: o, reason: 'putus');

({ApiClient api, _Stub stub, MemoryTokenStore tokens, List<int> unauthorized})
_make(List<_Handler> handlers, {String? token}) {
  final stub = _Stub(handlers);
  final tokens = MemoryTokenStore(token);
  final unauthorized = <int>[];
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
    ..httpClientAdapter = stub;
  final api = ApiClient(
    tokens: tokens,
    deviceId: 'test',
    onUnauthorized: () => unauthorized.add(1),
    dio: dio,
  );
  return (api: api, stub: stub, tokens: tokens, unauthorized: unauthorized);
}

void main() {
  test('sukses: body {data} di-unwrap', () async {
    final c = _make([
      (_) => _json(200, {
        'data': {'id': 'a'},
      }),
    ]);
    expect(await c.api.get('/x'), {'id': 'a'});
  });

  test('GET diulang sampai 3x pada 5xx lalu sukses', () async {
    final c = _make([
      (_) => _json(503, {}),
      (_) => _json(500, {}),
      (_) => _json(200, {'data': 1}),
    ]);
    expect(await c.api.get('/x'), 1);
    expect(c.stub.calls, hasLength(3));
  });

  test('GET menyerah setelah 3x dan melempar ApiException 5xx', () async {
    final c = _make([(_) => _json(500, {})]);
    await expectLater(
      c.api.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
    );
    expect(c.stub.calls, hasLength(3));
  });

  test('GET diulang saat jaringan putus; error menjadi status 0', () async {
    final c = _make([_netError]);
    await expectLater(
      c.api.get('/x'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true),
      ),
    );
    expect(c.stub.calls, hasLength(3));
  });

  test('POST/PUT/DELETE tidak pernah diulang otomatis (uang)', () async {
    for (final send in <Future<Object?> Function(ApiClient)>[
      (a) => a.post('/pay'),
      (a) => a.put('/x'),
      (a) => a.delete('/x'),
    ]) {
      final c = _make([(_) => _json(500, {})]);
      await expectLater(send(c.api), throwsA(isA<ApiException>()));
      expect(c.stub.calls, hasLength(1));
    }
  });

  test('4xx tidak diulang', () async {
    final c = _make([(_) => _json(404, {})]);
    await expectLater(c.api.get('/x'), throwsA(isA<ApiException>()));
    expect(c.stub.calls, hasLength(1));
  });

  test(
    'Idempotency-Key terkirim dan sama saat dikirim ulang oleh pemanggil',
    () async {
      final c = _make([
        (_) => _json(201, {'data': {}}),
      ]);
      await c.api.post('/pay', options: ApiClient.idempotent('kunci-1'));
      await c.api.post('/pay', options: ApiClient.idempotent('kunci-1'));
      expect(c.stub.calls.map((o) => o.headers['Idempotency-Key']), [
        'kunci-1',
        'kunci-1',
      ]);
    },
  );

  test('token dikirim ke host API', () async {
    final c = _make([
      (_) => _json(200, {'data': 1}),
    ], token: 'rahasia');
    await c.api.get('/x');
    expect(c.stub.calls.single.headers['Authorization'], 'Bearer rahasia');
  });

  test('token TIDAK bocor ke host lain', () async {
    final c = _make([
      (_) => _json(200, {'data': 1}),
    ], token: 'rahasia');
    await c.api.get('https://evil.example.org/x');
    expect(c.stub.calls.single.headers.containsKey('Authorization'), isFalse);
  });

  test('401 dengan token memicu onUnauthorized sekali', () async {
    final c = _make([(_) => _json(401, {})], token: 'rahasia');
    await expectLater(
      c.api.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)),
    );
    expect(c.unauthorized, hasLength(1));
  });

  test(
    '401 tanpa token (mis. salah sandi saat masuk) tidak mengeluarkan sesi',
    () async {
      final c = _make([(_) => _json(401, {})]);
      await expectLater(
        c.api.post('/auth/login'),
        throwsA(isA<ApiException>()),
      );
      expect(c.unauthorized, isEmpty);
    },
  );

  test('429 membaca Retry-After dan envelope error', () async {
    final c = _make([
      (_) => _json(
        429,
        {
          'error': {
            'code': 'TOO_MANY_ATTEMPTS',
            'message': 'Tunggu',
            'fields': {},
          },
        },
        headers: {
          'retry-after': ['42'],
        },
      ),
    ]);
    await expectLater(
      c.api.post('/auth/otp/send'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isRateLimited, 'rate', true)
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 42),
            )
            .having((e) => e.code, 'code', 'TOO_MANY_ATTEMPTS'),
      ),
    );
  });

  test('422 membawa fields per-input', () async {
    final c = _make([
      (_) => _json(422, {
        'error': {
          'code': 'VALIDATION_FAILED',
          'message': 'Periksa',
          'fields': {
            'phone': ['Salah'],
          },
        },
      }),
    ]);
    await expectLater(
      c.api.post('/auth/register'),
      throwsA(
        isA<ApiException>().having((e) => e.fields['phone'], 'phone', [
          'Salah',
        ]),
      ),
    );
  });

  test(
    'getPage membaca next_cursor di tingkat atas dan kunci tambahan',
    () async {
      final c = _make([
        (_) => _json(200, {
          'data': [
            {'id': 'a'},
            {'id': 'b'},
          ],
          'next_cursor': 'abc',
          'belum_dibaca': 3,
        }),
      ]);
      final p = await c.api.getPage<String>('/x', (j) => j['id'] as String);
      expect(p.items, ['a', 'b']);
      expect(p.nextCursor, 'abc');
      expect(p.extra['belum_dibaca'], 3);
    },
  );
}
