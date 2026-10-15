/// Nama enum Dart (camelCase) <-> nilai kawat API (snake_case).
String wire(Enum e) =>
    e.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// Nilai tak dikenal jatuh ke [fallback] (status baru dari server tidak boleh crash).
T enumFromWire<T extends Enum>(List<T> values, Object? s, T fallback) {
  for (final v in values) {
    if (wire(v) == s) return v;
  }
  return fallback;
}
