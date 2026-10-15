import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/storage/secure_token_store.dart';

typedef Json = Map<String, dynamic>;

typedef PinValidator = bool Function(
  X509Certificate? cert,
  String host,
  int port,
);

/// Hook certificate pinning. Diisi app saat `PINNED_SPKI` dipasang (hitung hash SPKI di sini).
/// Pinning aktif tetapi hook null = tolak semua koneksi (fail closed).
PinValidator? pinValidator;

const _uploadTimeout = Duration(seconds: 30);
final _apiHost = Uri.parse(Env.apiBaseUrl).host;

/// SATU klien HTTP. Sukses: body `{"data": ...}` di-unwrap. Gagal: selalu [ApiException].
class ApiClient {
  ApiClient({
    required TokenStore tokens,
    required String deviceId,
    required void Function() onUnauthorized,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: Env.apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               headers: {
                 'Accept': 'application/json',
                 'Accept-Language': 'id',
                 'X-App-Version': Env.appVersion,
                 'X-Device-Id': deviceId,
               },
             ),
           ) {
    final adapter = _dio.httpClientAdapter;
    if (Env.pinningEnabled && adapter is IOHttpClientAdapter) {
      adapter.validateCertificate = (c, h, p) =>
          pinValidator?.call(c, h, p) ?? false;
    }
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          final t = tokens.cached;
          if (t != null && o.uri.host == _apiHost) {
            o.headers['Authorization'] = 'Bearer $t';
          }
          h.next(o);
        },
        onError: (e, h) {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.headers.containsKey('Authorization')) {
            onUnauthorized();
          }
          h.next(e);
        },
      ),
    );
    // Log hanya metode, path, status. Tanpa header/body (token, PII).
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (r, h) {
            debugPrint(
              '[api] ${r.requestOptions.method} ${r.requestOptions.path} ${r.statusCode}',
            );
            h.next(r);
          },
          onError: (e, h) {
            debugPrint(
              '[api] ${e.requestOptions.method} ${e.requestOptions.path} ${e.response?.statusCode ?? e.type.name}',
            );
            h.next(e);
          },
        ),
      );
    }
  }

  final Dio _dio;

  /// Header Idempotency-Key untuk endpoint uang. Pakai ulang key yang sama saat retry.
  static Options idempotent(String key, {Options? base}) =>
      (base ?? Options()).copyWith(headers: {'Idempotency-Key': key});

  /// Opsi upload multipart (timeout 30 dtk).
  static Options get upload =>
      Options(sendTimeout: _uploadTimeout, receiveTimeout: _uploadTimeout);

  Future<Object?> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<Object?> post(
    String path, {
    Object? data,
    Options? options,
    ProgressCallback? onProgress,
  }) =>
      _send('POST', path, data: data, options: options, onProgress: onProgress);

  Future<Object?> put(String path, {Object? data}) =>
      _send('PUT', path, data: data);

  Future<Object?> patch(String path, {Object? data}) =>
      _send('PATCH', path, data: data);

  Future<Object?> delete(String path) => _send('DELETE', path);

  /// List berpaginasi: `{"data":[...], "meta":{"next_cursor":"..."}}`.
  Future<Paged<T>> getPage<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    final body = await _raw('GET', path, query: query);
    final map = body as Map;
    return Paged([
      for (final e in map['data'] as List) fromJson(e as Map<String, dynamic>),
    ], nextCursor: (map['meta'] as Map?)?['next_cursor'] as String?);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    ProgressCallback? onProgress,
  }) async {
    final body = await _raw(
      method,
      path,
      data: data,
      query: query,
      options: options,
      onProgress: onProgress,
    );
    return body is Map && body.containsKey('data') ? body['data'] : body;
  }

  Future<Object?> _raw(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    ProgressCallback? onProgress,
  }) async {
    // GET boleh retry otomatis 2x (backoff); tulis (terutama uang) tidak pernah.
    final attempts = method == 'GET' ? 3 : 1;
    for (var i = 1; ; i++) {
      try {
        final r = await _dio.request<Object?>(
          path,
          data: data,
          queryParameters: query,
          options: (options ?? Options()).copyWith(method: method),
          onSendProgress: onProgress,
        );
        return r.data;
      } on DioException catch (e) {
        final err = _toApi(e);
        final retryable = err.isNetwork || err.status >= 500;
        if (i >= attempts || !retryable) throw err;
        await Future<void>.delayed(Duration(milliseconds: 300 * i * i));
      }
    }
  }

  ApiException _toApi(DioException e) {
    final status = e.response?.statusCode;
    if (status != null) {
      final secs = int.tryParse(e.response?.headers.value('retry-after') ?? '');
      return ApiException.fromBody(
        status,
        e.response?.data,
        retryAfter: secs != null && secs > 0 ? Duration(seconds: secs) : null,
      );
    }
    return ApiException(
      status: ApiException.network,
      code: 'NETWORK',
      message: ApiException.defaultMessage(ApiException.network),
    );
  }
}
