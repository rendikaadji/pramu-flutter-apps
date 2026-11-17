/// Satu halaman hasil daftar dengan paginasi kursor (Docs/15 §3.1).
class Paged<T> {
  const Paged(
    this.items, {
    this.nextCursor,
    this.extra = const {},
    this.berikutnya,
  });
  final List<T> items;
  final String? nextCursor;
  final Map<String, dynamic> extra;

  /// Memuat halaman sesudah ini dengan permintaan yang sama; null bila ini halaman terakhir.
  final Future<Paged<T>> Function()? berikutnya;
  bool get hasMore => nextCursor != null;
}
