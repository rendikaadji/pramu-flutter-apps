import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/api/api_exception.dart';

void main() {
  test('fromBody membaca envelope lengkap dengan fields', () {
    final e = ApiException.fromBody(422, {
      'error': {
        'code': 'VALIDATION_FAILED',
        'message': 'Periksa data.',
        'fields': {
          'phone': ['Sudah terdaftar'],
          'email': ['Salah', 'Kosong'],
        },
      },
    });
    expect(e.status, 422);
    expect(e.code, 'VALIDATION_FAILED');
    expect(e.message, 'Periksa data.');
    expect(e.fields['email'], ['Salah', 'Kosong']);
    expect(e.isValidation, isTrue);
  });

  for (final body in <Object?>[
    null,
    'html 502',
    <String, dynamic>{},
    {'error': <String, dynamic>{}},
  ]) {
    test('fromBody tahan body tak terduga: $body', () {
      final e = ApiException.fromBody(502, body);
      expect(e.code, 'UNKNOWN');
      expect(e.message, 'Ada masalah di sisi kami. Coba lagi sebentar.');
      expect(e.fields, isEmpty);
    });
  }

  test('fromBody tahan field bukan list dan code bukan string', () {
    final e = ApiException.fromBody(422, {
      'error': {
        'code': 42,
        'message': ['bukan string'],
        'fields': {
          'phone': 'bukan list',
          'email': ['Salah', 7],
        },
      },
    });
    expect(e.code, 'UNKNOWN');
    expect(e.message, ApiException.defaultMessage(422));
    expect(e.fields.containsKey('phone'), isFalse);
    expect(e.fields['email'], ['Salah', '7']);
  });
}
