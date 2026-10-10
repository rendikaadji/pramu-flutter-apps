import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.cursor,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<T> items;
  final String? cursor;
  final bool loading;
  final bool loadingMore;
  final ApiException? error;

  bool get hasMore => cursor != null;
}

/// Daftar berkursor (infinite scroll). Filter baru memuat ulang dari awal;
/// `reload(keep: true)` untuk pull-to-refresh (daftar lama tetap tampil).
abstract class PagedNotifier<T, F> extends Notifier<PagedState<T>> {
  F get emptyFilter;
  Future<Paged<T>> fetch(F filter, String? cursor);

  late F _filter;
  int _gen = 0;

  F get filter => _filter;

  @override
  PagedState<T> build() {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    _filter = emptyFilter;
    Future.microtask(reload);
    return PagedState<T>();
  }

  Future<void> reload({F? filter, bool keep = false}) async {
    if (filter != null) _filter = filter;
    final gen = ++_gen;
    final old = keep ? state.items : <T>[];
    state = PagedState<T>(items: old);
    try {
      final p = await fetch(_filter, null);
      if (gen != _gen || !ref.mounted) return;
      state = PagedState<T>(
        items: p.items,
        cursor: p.nextCursor,
        loading: false,
      );
    } catch (e) {
      if (gen != _gen || !ref.mounted) return;
      state = PagedState<T>(
        items: old,
        loading: false,
        error: asApiException(e),
      );
    }
  }

  Future<void> loadMore({bool retry = false}) async {
    final s = state;
    // error sebelumnya: tunggu pengguna menekan "Coba lagi" (retry: true), bukan tiap scroll
    if (s.loading || s.loadingMore || s.cursor == null) return;
    if (s.error != null && !retry) return;
    final gen = _gen;
    state = PagedState<T>(
      items: s.items,
      cursor: s.cursor,
      loading: false,
      loadingMore: true,
    );
    try {
      final p = await fetch(_filter, s.cursor);
      if (gen != _gen || !ref.mounted) return;
      state = PagedState<T>(
        items: [...s.items, ...p.items],
        cursor: p.nextCursor,
        loading: false,
      );
    } catch (e) {
      if (gen != _gen || !ref.mounted) return;
      state = PagedState<T>(
        items: s.items,
        cursor: s.cursor,
        loading: false,
        error: asApiException(e),
      );
    }
  }
}
