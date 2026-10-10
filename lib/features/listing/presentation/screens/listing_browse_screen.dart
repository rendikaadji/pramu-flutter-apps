import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/filter_sheet.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/listing_card.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/paged_list.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/search_header.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-41 Cari lowongan (tab Asisten). Filter rating tidak ada: API lowongan tidak mendukungnya.
class ListingBrowseScreen extends ConsumerStatefulWidget {
  const ListingBrowseScreen({super.key});

  @override
  ConsumerState<ListingBrowseScreen> createState() => _State();
}

class _State extends ConsumerState<ListingBrowseScreen> {
  String _query = '';
  FilterValues _f = const FilterValues();

  bool get _filtered => _query.isNotEmpty || _f.activeCount > 0;

  void _apply() => ref
      .read(listingBrowseProvider.notifier)
      .reload(
        filter: ListingFilter(
          query: _query.isEmpty ? null : _query,
          category: _f.category,
          city: _f.city,
          maxBudget: _f.maxRate,
          unit: _f.unit,
        ),
      );

  FilterValues _with({
    String? category,
    bool setCategory = false,
    FilterValues? from,
  }) {
    final b = from ?? _f;
    return FilterValues(
      category: setCategory ? category : b.category,
      city: b.city,
      maxRate: b.maxRate,
      unit: b.unit,
    );
  }

  Future<void> _openFilter() async {
    final r = await showFilterSheet(context, initial: _f, showRating: false);
    if (r == null) return;
    setState(
      () => _f = FilterValues(
        category: _f.category,
        city: r.city,
        maxRate: r.maxRate,
        unit: r.unit,
      ),
    );
    _apply();
  }

  void _reset() {
    setState(() {
      _query = '';
      _f = const FilterValues();
    });
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(listingBrowseProvider);
    final n = ref.read(listingBrowseProvider.notifier);
    return AppScaffold(
      title: 'Cari lowongan',
      body: Column(
        children: [
          SearchHeader(
            label: 'Judul atau kata kunci',
            hint: 'Mis. juru masak, pengasuh anak',
            category: _f.category,
            activeFilters: _f.activeCount - (_f.category == null ? 0 : 1),
            onQuery: (q) {
              _query = q;
              _apply();
            },
            onCategory: (c) {
              setState(() => _f = _with(category: c, setCategory: true));
              _apply();
            },
            onFilter: _openFilter,
          ),
          Expanded(
            child: PagedListView<Listing>(
              state: s,
              onRefresh: () => n.reload(keep: true),
              onLoadMore: n.loadMore,
              onRetryMore: () => n.loadMore(retry: true),
              empty: EmptyState(
                icon: LucideIcons.briefcase,
                title: _filtered ? 'Tidak ada hasil' : 'Belum ada lowongan',
                message: 'Belum ada lowongan yang cocok.',
                actionLabel: _filtered ? 'Reset filter' : null,
                onAction: _reset,
              ),
              itemBuilder: (ctx, l) => ListingCard(
                key: K.listingCard(l.id),
                listing: l,
                onTap: () => ctx.push(Routes.listingDetail(l.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
