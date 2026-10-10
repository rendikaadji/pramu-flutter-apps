import 'dart:math';

const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// ULID 26 karakter (Crockford base32): 48-bit waktu + 80-bit acak.
String ulid({DateTime? at, Random? random}) {
  final r = random ?? Random.secure();
  var t = (at ?? DateTime.now()).millisecondsSinceEpoch;
  final time = List.filled(10, '');
  for (var i = 9; i >= 0; i--) {
    time[i] = _crockford[t % 32];
    t ~/= 32;
  }
  final rand = List.generate(16, (_) => _crockford[r.nextInt(32)]);
  return time.join() + rand.join();
}

String uuidV4([Random? random]) {
  final r = random ?? Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Satu kunci per NIAT bayar/tarik; pakai ulang saat retry.
String newIdempotencyKey() => uuidV4();
