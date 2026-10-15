import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Bar cari besar (debounce 400 ms) + tombol Filter + tab pil kategori.
class SearchHeader extends StatefulWidget {
  const SearchHeader({
    super.key,
    required this.label,
    this.hint = 'Ketik kata kunci',
    required this.category,
    required this.activeFilters,
    required this.onQuery,
    required this.onCategory,
    required this.onFilter,
  });

  final String label;
  final String hint;
  final String? category;
  final int activeFilters;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;
  final VoidCallback onFilter;

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  Timer? _debounce;

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.onQuery(v.trim()),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['Semua', ...kCategories];
    final idx = widget.category == null
        ? 0
        : kCategories.indexOf(widget.category!) + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: widget.label,
          container: true,
          child: SearchField(
            key: K.searchField,
            hint: widget.hint,
            onChanged: _changed,
            onSubmitted: widget.onQuery,
            trailing: _FilterButton(
              count: widget.activeFilters,
              onTap: widget.onFilter,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        SegmentedTabs(
          labels: cats,
          index: idx < 0 ? 0 : idx,
          onChanged: (i) =>
              widget.onCategory(i == 0 ? null : kCategories[i - 1]),
        ),
        const SizedBox(height: AppSpace.s12),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: count == 0 ? 'Filter' : 'Filter, $count aktif',
      excludeSemantics: true,
      onTap: onTap,
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: t.accent,
        textColor: t.onAccent,
        child: Material(
          key: K.filterButton,
          color: t.primary,
          borderRadius: AppRadius.brButton,
          child: InkWell(
            borderRadius: AppRadius.brButton,
            onTap: onTap,
            child: SizedBox.square(
              dimension: 56,
              child: Icon(
                LucideIcons.slidersHorizontal,
                size: 22,
                color: t.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
