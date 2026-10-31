import 'package:flutter_test/flutter_test.dart';
import 'package:pramu_apps/core/validators.dart';

void main() {
  group('HP', () {
    for (final ok in [
      '081234567890',
      '+6281234567890',
      '0812-3456-7890',
      '08123456789',
    ]) {
      test('valid $ok', () => expect(validatePhone(ok), isNull));
    }
    for (final bad in [
      '',
      '12345',
      '0712345678',
      '+6212345678',
      '0812345',
      'abc',
    ]) {
      test('tidak valid "$bad"', () => expect(validatePhone(bad), isNotNull));
    }
    test('normalizePhone ke +62', () {
      expect(normalizePhone('0812-3456-7890'), '+6281234567890');
      expect(normalizePhone('+6281234567890'), '+6281234567890');
    });
  });

  test('email, sandi, NIK', () {
    expect(validateEmail('rina@example.com'), isNull);
    expect(validateEmail('rina@'), isNotNull);
    expect(validatePassword('1234567'), isNotNull);
    expect(validatePassword('12345678'), isNull);
    expect(validateNik('3174012345678901'), isNull);
    expect(validateNik('317401234567890'), isNotNull);
    expect(validateNik('31740123456789ab'), isNotNull);
  });

  group('URL allowlist', () {
    for (final ok in [
      'https://meet.google.com/abc-defg-hij',
      'https://MEET.google.com/x',
    ]) {
      test('meeting ok $ok', () => expect(isAllowedMeetingUrl(ok), isTrue));
    }
    for (final bad in <String?>[
      'http://meet.google.com/abc',
      'https://meet.google.com.evil.com/abc',
      'https://evil.com/meet.google.com',
      'https://meet.google.com@evil.com/x',
      'https://user:pw@meet.google.com/x',
      'https://meet.google.com:8443/x',
      'javascript:alert(1)',
      'intent://meet.google.com#Intent;end',
      '',
      null,
    ]) {
      test(
        'meeting ditolak $bad',
        () => expect(isAllowedMeetingUrl(bad), isFalse),
      );
    }
    test('invoice Xendit', () {
      expect(isAllowedInvoiceUrl('https://checkout.xendit.co/web/abc'), isTrue);
      expect(
        isAllowedInvoiceUrl('https://checkout.xendit.co.evil.io/web/abc'),
        isFalse,
      );
      expect(isAllowedInvoiceUrl('http://checkout.xendit.co/web/abc'), isFalse);
      expect(isAllowedInvoiceUrl('https://meet.google.com/abc'), isFalse);
    });
    test('WhatsApp balik hanya wa.me', () {
      expect(
        isAllowedWhatsAppUrl('https://wa.me/6281200000000?text=Kode%20K7M2QX'),
        isTrue,
      );
      expect(
        isAllowedWhatsAppUrl('https://wa.me.evil.io/6281200000000'),
        isFalse,
      );
      expect(isAllowedWhatsAppUrl('http://wa.me/6281200000000'), isFalse);
      expect(
        isAllowedWhatsAppUrl('https://api.whatsapp.com/send?phone=1'),
        isFalse,
      );
      expect(isAllowedWhatsAppUrl('https://user@wa.me/1'), isFalse);
      expect(isAllowedWhatsAppUrl(null), isFalse);
    });
  });

  group('ULID', () {
    test('valid', () => expect(isUlid('01ARZ3NDEKTSV4RRFFQ69G5FAV'), isTrue));
    for (final bad in <String?>[
      '',
      '123',
      '01ARZ3NDEKTSV4RRFFQ69G5FA',
      '01ARZ3NDEKTSV4RRFFQ69G5FAVX',
      '01arz3ndektsv4rrffq69g5fav',
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '../../etc/passwd',
      null,
    ]) {
      test('tidak valid $bad', () => expect(isUlid(bad), isFalse));
    }
  });
}
