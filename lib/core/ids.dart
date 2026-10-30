import 'dart:math';

/// UUID v4 acak. ID data dibuat server (UUIDv7); klien hanya membuat ID perangkat dan kunci idempoten.
String uuidV4([Random? random]) {
  final r = random ?? Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Satu kunci per NIAT aksi yang mengubah status atau uang; pakai ulang saat retry (Docs/15 §2.4).
String newIdempotencyKey() => uuidV4();
