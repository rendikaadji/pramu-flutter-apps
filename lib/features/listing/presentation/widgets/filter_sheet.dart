import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/chip_select.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

class FilterValues {
  const FilterValues({
    this.category,
    this.city,
    this.maxRate,
    this.unit,
    this.minRating,
  });

  final String? category;
  final String? city;
  final int? maxRate;
  final PeriodUnit? unit;
  final double? minRating;

  int get activeCount =>
      [category, city, maxRate, unit, minRating].where((e) => e != null).length;
}

const _ratings = <double>[3, 4, 4.5];

/// Bottom sheet filter (kota, tarif, periode, rating). Kembali `FilterValues`
/// (kosong = reset) atau null bila ditutup.
Future<FilterValues?> showFilterSheet(
  BuildContext context, {
  required FilterValues initial,
  bool showRating = true,
}) => showModalBottomSheet<FilterValues>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FilterSheet(initial: initial, showRating: showRating),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.showRating});
  final FilterValues initial;
  final bool showRating;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _city = widget.initial.city;
  late PeriodUnit? _unit = widget.initial.unit;
  late double? _rating = widget.initial.minRating;
  late final _rate = TextEditingController(
    text: widget.initial.maxRate?.toString() ?? '',
  );

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Widget _group(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.label),
        const SizedBox(height: AppSpace.s8),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.s16,
          0,
          AppSpace.s16,
          AppSpace.s16 + inset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter', style: context.text.h2),
            const SizedBox(height: AppSpace.s16),
            _group(
              'Kota',
              ChipSelect<String>(
                options: kCities,
                labelOf: (s) => s,
                selected: _city,
                onChanged: (v) => setState(() => _city = v),
              ),
            ),
            _group(
              'Periode',
              ChipSelect<PeriodUnit>(
                options: const [
                  PeriodUnit.daily,
                  PeriodUnit.weekly,
                  PeriodUnit.monthly,
                ],
                labelOf: (u) => u.label,
                selected: _unit,
                onChanged: (v) => setState(() => _unit = v),
              ),
            ),
            AppTextField(
              key: K.filterRate,
              label: 'Tarif maksimum per periode',
              prefixText: 'Rp',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: _rate,
            ),
            const SizedBox(height: AppSpace.s16),
            if (widget.showRating)
              _group(
                'Rating minimum',
                ChipSelect<double>(
                  options: _ratings,
                  labelOf: (r) => '${r.toString().replaceAll('.', ',')}+',
                  selected: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: K.filterReset,
                    label: 'Reset',
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        Navigator.pop(context, const FilterValues()),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: AppButton(
                    key: K.filterApply,
                    label: 'Terapkan',
                    onPressed: () => Navigator.pop(
                      context,
                      FilterValues(
                        category: widget.initial.category,
                        city: _city,
                        unit: _unit,
                        minRating: _rating,
                        maxRate: parseRupiah(_rate.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
