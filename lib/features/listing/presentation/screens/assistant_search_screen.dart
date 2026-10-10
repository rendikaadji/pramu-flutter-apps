import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/assistant_card.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/filter_sheet.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/paged_list.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/search_header.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-30 Cari asisten (tab Pencari).
class AssistantSearchScreen extends ConsumerStatefulWidget {
  const AssistantSearchScreen({super.key});

  @override
  ConsumerState<AssistantSearchScreen> createState() => _State();
}

class _State extends ConsumerState<AssistantSearchScreen> {
  String _query = '';
  FilterValues _f = const FilterValues();

  bool get _filtered => _query.isNotEmpty || _f.activeCount > 0;

  void _apply() => ref
      .read(assistantSearchProvider.notifier)
      .reload(
        filter: AssistantFilter(
          query: _query.isEmpty ? null : _query,
          category: _f.category,
          city: _f.city,
          maxRate: _f.maxRate,
          unit: _f.unit,
          minRating: _f.minRating,
        ),
      );

  Future<void> _openFilter() async {
    final r = await showFilterSheet(context, initial: _f);
    if (r == null) return;
    setState(
      () => _f = FilterValues(
        category: _f.category,
        city: r.city,
        maxRate: r.maxRate,
        unit: r.unit,
        minRating: r.minRating,
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
    final s = ref.watch(assistantSearchProvider);
    final n = ref.read(assistantSearchProvider.notifier);
    return AppScaffold(
      title: 'Cari asisten',
      glow: true,
      body: Column(
        children: [
          SearchHeader(
            label: 'Nama atau keahlian',
            hint: 'Mis. memasak, pengasuh anak',
            category: _f.category,
            activeFilters: _f.activeCount - (_f.category == null ? 0 : 1),
            onQuery: (q) {
              _query = q;
              _apply();
            },
            onCategory: (c) {
              setState(
                () => _f = FilterValues(
                  category: c,
                  city: _f.city,
                  maxRate: _f.maxRate,
                  unit: _f.unit,
                  minRating: _f.minRating,
                ),
              );
              _apply();
            },
            onFilter: _openFilter,
          ),
          Expanded(
            child: PagedListView<AssistantProfile>(
              state: s,
              onRefresh: () => n.reload(keep: true),
              onLoadMore: n.loadMore,
              onRetryMore: () => n.loadMore(retry: true),
              empty: EmptyState(
                icon: LucideIcons.search,
                title: _filtered ? 'Tidak ada hasil' : 'Belum ada asisten',
                message: _filtered
                    ? 'Belum ada asisten yang cocok. Coba perluas kota atau rentang tarif.'
                    : 'Belum ada asisten yang terdaftar. Coba lagi nanti.',
                actionLabel: _filtered ? 'Reset filter' : null,
                onAction: _reset,
              ),
              itemBuilder: (ctx, p) => AssistantCard(
                key: K.assistantCard(p.userId),
                profile: p,
                onTap: () => ctx.push(Routes.assistantProfile(p.userId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
