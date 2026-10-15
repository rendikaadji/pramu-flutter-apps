import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/application/domain/application.dart';

void main() {
  setUpAll(initLocale);

  group('formatRupiah', () {
    for (final (v, s) in [
      (0, 'Rp0'),
      (500, 'Rp500'),
      (25000, 'Rp25.000'),
      (1500000, 'Rp1.500.000'),
    ]) {
      test('$v -> $s', () => expect(formatRupiah(v), s));
    }
  });

  group('parseRupiah', () {
    for (final (input, want) in <(String, int?)>[
      ('25000', 25000),
      ('Rp25.000', 25000),
      ('Rp 1.500.000', 1500000),
      ('25.000,00', 25000),
      ('25.000,50', null),
      ('25,5', null),
      ('-5000', null),
      ('', null),
      ('abc', null),
    ]) {
      test('"$input" -> $want', () => expect(parseRupiah(input), want));
    }
  });

  test('WIB: UTC 03:00 tampil 10.00 WIB, fromWib kebalikannya', () {
    final t = DateTime.utc(2026, 10, 10, 3);
    expect(formatTime(t), '10.00');
    expect(formatDateTime(t), '10 Okt 2026, 10.00 WIB');
    expect(fromWib(2026, 10, 10, 10), t);
  });

  test('ulid valid, unik, dan uuidV4 berformat benar', () {
    final a = ulid();
    expect(isUlid(a), isTrue);
    expect(a, isNot(ulid()));
    expect(
      uuidV4(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('wire/enumFromWire: snake_case dan fallback unknown', () {
    expect(wire(ApplicationStatus.interviewScheduled), 'interview_scheduled');
    expect(
      ApplicationStatus.from('interview_scheduled'),
      ApplicationStatus.interviewScheduled,
    );
    expect(ApplicationStatus.from('status_baru'), ApplicationStatus.unknown);
    expect(ApplicationStatus.from(null), ApplicationStatus.unknown);
  });
}
