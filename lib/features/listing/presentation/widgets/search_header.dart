import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/chip_select.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Bar cari (debounce 400 ms) + tombol Filter + chip kategori.
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppTextField(
        key: K.searchField,
        label: widget.label,
        hint: widget.hint,
        textInputAction: TextInputAction.search,
        onChanged: _changed,
        onSubmitted: widget.onQuery,
      ),
      const SizedBox(height: AppSpace.s12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppButton(
              key: K.filterButton,
              label: widget.activeFilters == 0
                  ? 'Filter'
                  : 'Filter (${widget.activeFilters})',
              icon: LucideIcons.slidersHorizontal,
              variant: widget.activeFilters == 0
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.tonal,
              expand: false,
              onPressed: widget.onFilter,
            ),
            const SizedBox(width: AppSpace.s8),
            ChipSelect<String>(
              options: kCategories,
              labelOf: (s) => s,
              selected: widget.category,
              onChanged: widget.onCategory,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s8),
    ],
  );
}
