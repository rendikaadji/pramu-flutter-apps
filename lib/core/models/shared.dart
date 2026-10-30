/// Satu halaman hasil daftar dengan paginasi kursor (Docs/15 §3.1).
class Paged<T> {
  const Paged(this.items, {this.nextCursor});
  final List<T> items;
  final String? nextCursor;
  bool get hasMore => nextCursor != null;
}
