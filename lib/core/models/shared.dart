/// Satu halaman hasil daftar dengan paginasi kursor (Docs/15 §3.1).
class Paged<T> {
  const Paged(this.items, {this.nextCursor, this.extra = const {}});
  final List<T> items;
  final String? nextCursor;
  final Map<String, dynamic> extra;
  bool get hasMore => nextCursor != null;
}
