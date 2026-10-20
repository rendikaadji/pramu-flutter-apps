import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/listing/data/listing_providers.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/chip_select.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/icon_info_row.dart';
import 'package:pramu_apps/shared/app_ui/wib_picker.dart';

const _steps = [
  'Kategori dan judul',
  'Deskripsi dan kota',
  'Periode dan budget',
  'Pertanyaan untuk pelamar',
];

const _stepFields = <List<String>>[
  ['category', 'title'],
  ['description', 'city'],
  ['period_count', 'start_date', 'budget_min', 'budget_max'],
  ['screening_questions'],
];

enum _Exit { keep, discard, save }

/// M-33 Buat lowongan: wizard 4 langkah, draf tersimpan di server.
class ListingWizardScreen extends ConsumerStatefulWidget {
  const ListingWizardScreen({super.key, this.draftId});
  final String? draftId;

  @override
  ConsumerState<ListingWizardScreen> createState() => _State();
}

class _State extends ConsumerState<ListingWizardScreen> with ApiActionMixin {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _count = TextEditingController(text: '1');
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _questions = <TextEditingController>[];

  int _step = 0;
  String? _category;
  String? _city;
  PeriodUnit _unit = PeriodUnit.monthly;
  DateTime? _start;
  bool _skck = false;
  bool _skip = false;

  String? _id;
  bool _dirty = false;
  bool _loadingDraft = false;
  ApiException? _loadError;
  final _local = <String, String>{};

  @override
  void initState() {
    super.initState();
    _id = widget.draftId;
    if (_id != null) _loadDraft();
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _count, _min, _max, ..._questions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDraft() async {
    setState(() {
      _loadingDraft = true;
      _loadError = null;
    });
    try {
      final l = await ref.read(listingRepositoryProvider).get(_id!);
      if (!mounted) return;
      if (!l.status.canEdit) {
        context.pushReplacement(
          l.status.canPay
              ? Routes.listingPay(l.id)
              : Routes.listingManage(l.id),
        );
        return;
      }
      setState(() {
        _title.text = l.title;
        _desc.text = l.description;
        _count.text = '${l.periodCount}';
        _min.text = '${l.budgetMin}';
        _max.text = '${l.budgetMax}';
        _category = l.category;
        _city = l.city;
        _unit = l.unit;
        _start = l.startDate;
        _skck = l.requireSkck;
        _skip = l.skipInterview;
        for (final q in l.screeningQuestions) {
          _questions.add(TextEditingController(text: q));
        }
        _loadingDraft = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDraft = false;
        _loadError = asApiException(e);
      });
    }
  }

  void _touch([String? key]) {
    setState(() {
      _dirty = true;
      if (key != null) _local.remove(key);
      clearActionError();
    });
  }

  Map<String, String> _validate() {
    final e = <String, String>{};
    if (_category == null) e['category'] = 'Pilih kategori';
    if (_title.text.trim().isEmpty) e['title'] = 'Tulis judul lowongan';
    if (_city == null) e['city'] = 'Pilih kota tempat bekerja';
    final n = int.tryParse(_count.text.trim());
    if (n == null || n < 1) e['period_count'] = 'Isi minimal 1 periode';
    if (_start == null) e['start_date'] = 'Pilih tanggal mulai';
    final min = parseRupiah(_min.text);
    final max = parseRupiah(_max.text);
    if (min == null || min <= 0) e['budget_min'] = 'Isi budget lebih dari Rp0';
    if (max == null || max <= 0) {
      e['budget_max'] = 'Isi budget lebih dari Rp0';
    } else if (min != null && max < min) {
      e['budget_max'] = 'Budget maksimum harus lebih besar dari minimum';
    }
    return e;
  }

  bool get _savable => _validate().isEmpty;

  ListingInput _input() => ListingInput(
    title: _title.text.trim(),
    category: _category!,
    description: _desc.text.trim(),
    city: _city!,
    unit: _unit,
    periodCount: int.parse(_count.text.trim()),
    startDate: _start!,
    budgetMin: parseRupiah(_min.text)!,
    budgetMax: parseRupiah(_max.text)!,
    requireSkck: _skck,
    skipInterview: _skip,
    screeningQuestions: [
      for (final c in _questions)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ],
  );

  /// Simpan draf ke server. 422 server dipetakan ke field + langkahnya.
  Future<bool> _save() async {
    final ok = await act(() async {
      final l = await ref
          .read(listingRepositoryProvider)
          .saveDraft(_input(), id: _id);
      _id = l.id;
      _dirty = false;
      ref.invalidate(myListingsProvider);
    });
    if (!ok && actionError?.isValidation == true && mounted) {
      final keys = actionError!.fields.keys.toSet();
      final i = _stepFields.indexWhere((s) => s.any(keys.contains));
      if (i >= 0) setState(() => _step = i);
    }
    return ok;
  }

  Future<void> _saveTapped() async {
    if (await _save() && mounted) {
      AppSnack.show(context, 'Draf sudah tersimpan.', success: true);
    }
  }

  Future<void> _next() async {
    final all = _validate();
    final mine = {
      for (final k in _stepFields[_step])
        if (all.containsKey(k)) k: all[k]!,
    };
    if (_step == 0 && _category == null) mine['category'] = 'Pilih kategori';
    if (mine.isNotEmpty) {
      setState(() => _local.addAll(mine));
      return;
    }
    if (_step == 2) {
      if (!await _save()) return;
      if (mounted) setState(() => _step = 3);
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    if (all.isNotEmpty) {
      final first = _stepFields.indexWhere((s) => s.any(all.containsKey));
      setState(() {
        _local.addAll(all);
        _step = first;
      });
      return;
    }
    if (await _save() && mounted) {
      context.pushReplacement(Routes.listingPay(_id!));
    }
  }

  Future<void> _onBack() async {
    if (_step > 0) {
      setState(() => _step--);
      return;
    }
    if (!_dirty) {
      popOrGo(context, Routes.seekerJobs);
      return;
    }
    if (_savable) {
      final r = await showAdaptiveDialog<_Exit>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Simpan draf?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lowongan ini belum dibayar. Simpan sebagai draf untuk dilanjutkan nanti.',
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                label: 'Simpan draf',
                onPressed: () => Navigator.pop(ctx, _Exit.save),
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Lanjut mengisi',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx, _Exit.keep),
              ),
              AppButton(
                label: 'Buang draf',
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.pop(ctx, _Exit.discard),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      if (r == _Exit.discard) popOrGo(context, Routes.seekerJobs);
      if (r == _Exit.save && await _save() && mounted) {
        popOrGo(context, Routes.seekerJobs);
      }
      return;
    }
    final leave = await ConfirmDialog.show(
      context,
      title: 'Keluar tanpa menyimpan?',
      message: 'Isian belum lengkap, jadi draf belum bisa disimpan.',
      confirmLabel: 'Keluar',
      cancelLabel: 'Lanjut mengisi',
      destructive: true,
    );
    if (leave && mounted) popOrGo(context, Routes.seekerJobs);
  }

  Future<void> _pickDate() async {
    final d = await pickWibDate(context, initial: _start);
    if (d != null) {
      setState(() => _start = d);
      _touch('start_date');
    }
  }

  String? _err(String key) => _local[key] ?? fieldError(key);

  Widget _field(String key, Widget Function(String? err) build) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s16),
    child: build(_err(key)),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.s8),
    child: Text(text, style: context.text.label),
  );

  List<Widget> _stepBody() => switch (_step) {
    0 => [
      _label('Kategori'),
      ChipSelect<String>(
        options: kCategories,
        labelOf: (s) => s,
        selected: _category,
        clearable: false,
        onChanged: (v) {
          setState(() => _category = v);
          _touch('category');
        },
      ),
      if (_err('category') != null) FieldErrorText(_err('category')!),
      const SizedBox(height: AppSpace.s16),
      _field(
        'title',
        (e) => AppTextField(
          key: K.listingTitle,
          label: 'Judul lowongan',
          prefixIcon: LucideIcons.fileText,
          hint: 'Contoh: Pengasuh anak usia 3 tahun',
          controller: _title,
          maxLength: 80,
          errorText: e,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _touch('title'),
        ),
      ),
    ],
    1 => [
      _field(
        'description',
        (e) => AppTextField(
          key: K.listingDescription,
          label: 'Deskripsi pekerjaan',
          prefixIcon: LucideIcons.alignLeft,
          helper: 'Jelaskan tugas, jam kerja, dan kebutuhan khusus.',
          controller: _desc,
          maxLines: 5,
          maxLength: 1000,
          showCounter: true,
          errorText: e,
          onChanged: (_) => _touch('description'),
        ),
      ),
      _label('Kota'),
      ChipSelect<String>(
        options: kCities,
        labelOf: (s) => s,
        selected: _city,
        clearable: false,
        onChanged: (v) {
          setState(() => _city = v);
          _touch('city');
        },
      ),
      if (_err('city') != null) FieldErrorText(_err('city')!),
    ],
    2 => [
      _label('Jenis periode'),
      ChipSelect<PeriodUnit>(
        options: const [
          PeriodUnit.daily,
          PeriodUnit.weekly,
          PeriodUnit.monthly,
        ],
        labelOf: (u) => u.label,
        selected: _unit,
        clearable: false,
        onChanged: (v) {
          setState(() => _unit = v ?? _unit);
          _touch();
        },
      ),
      const SizedBox(height: AppSpace.s16),
      _field(
        'period_count',
        (e) => AppTextField(
          key: K.listingPeriodCount,
          label: 'Jumlah periode',
          prefixIcon: LucideIcons.hash,
          controller: _count,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3,
          errorText: e,
          onChanged: (_) => _touch('period_count'),
        ),
      ),
      _label('Tanggal mulai'),
      AppButton(
        key: K.listingStartDate,
        label: _start == null ? 'Pilih tanggal' : formatDate(_start!),
        icon: LucideIcons.calendar,
        variant: AppButtonVariant.secondary,
        onPressed: _pickDate,
      ),
      if (_err('start_date') != null) FieldErrorText(_err('start_date')!),
      const SizedBox(height: AppSpace.s16),
      _field(
        'budget_min',
        (e) => AppTextField(
          key: K.listingBudgetMin,
          label: 'Budget minimum per periode',
          prefixText: 'Rp',
          controller: _min,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: e,
          onChanged: (_) => _touch('budget_min'),
        ),
      ),
      _field(
        'budget_max',
        (e) => AppTextField(
          key: K.listingBudgetMax,
          label: 'Budget maksimum per periode',
          prefixText: 'Rp',
          controller: _max,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: e,
          onChanged: (_) => _touch('budget_max'),
        ),
      ),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              SwitchListTile(
                key: K.listingRequireSkck,
                contentPadding: EdgeInsets.zero,
                title: const Text('Wajib SKCK'),
                subtitle: const Text(
                  'Hanya pelamar dengan SKCK terverifikasi yang bisa melamar.',
                ),
                value: _skck,
                onChanged: (v) {
                  setState(() => _skck = v);
                  _touch();
                },
              ),
              Divider(height: 1, color: context.tokens.borderSubtle),
              SwitchListTile(
                key: K.listingSkipInterview,
                contentPadding: EdgeInsets.zero,
                title: const Text('Lewati wawancara'),
                subtitle: const Text(
                  'Anda bisa langsung menerima pelamar tanpa wawancara.',
                ),
                value: _skip,
                onChanged: (v) {
                  setState(() => _skip = v);
                  _touch();
                },
              ),
            ],
          ),
        ),
      ),
    ],
    _ => [
      Text(
        'Pertanyaan untuk pelamar (opsional, maksimal 5)',
        style: context.text.label,
      ),
      const SizedBox(height: AppSpace.s8),
      for (var i = 0; i < _questions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Pertanyaan ${i + 1}',
                  controller: _questions[i],
                  maxLength: 140,
                  onChanged: (_) => _touch('screening_questions'),
                ),
              ),
              AppIconButton(
                icon: LucideIcons.trash2,
                label: 'Hapus pertanyaan ${i + 1}',
                onPressed: () {
                  setState(() => _questions.removeAt(i).dispose());
                  _touch();
                },
              ),
            ],
          ),
        ),
      if (_err('screening_questions') != null)
        FieldErrorText(_err('screening_questions')!),
      if (_questions.length < 5)
        AppButton(
          key: K.listingQuestionAdd,
          label: 'Tambah pertanyaan',
          icon: LucideIcons.plus,
          variant: AppButtonVariant.secondary,
          expand: false,
          onPressed: () {
            setState(() => _questions.add(TextEditingController()));
            _touch();
          },
        ),
      const SizedBox(height: AppSpace.s24),
      const SectionHeader('Ringkasan'),
      const SizedBox(height: AppSpace.s8),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title.text.trim().isEmpty ? '-' : _title.text.trim(),
              style: context.text.h3,
            ),
            const SizedBox(height: AppSpace.s8),
            MoneyText(
              '${formatRupiah(parseRupiah(_min.text) ?? 0)} - ${formatRupiah(parseRupiah(_max.text) ?? 0)}',
            ),
            Text(
              'Budget per ${_unit.label.toLowerCase()}',
              style: context.text.bodySm.copyWith(
                color: context.tokens.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.s12),
            IconInfoRow(
              icon: LucideIcons.briefcase,
              text: '${_category ?? '-'} · ${_city ?? '-'}',
            ),
            const SizedBox(height: AppSpace.s8),
            IconInfoRow(
              icon: LucideIcons.calendar,
              text:
                  '${_count.text} periode ${_unit.label.toLowerCase()}'
                  '${_start == null ? '' : ', mulai ${formatDate(_start!)}'}',
            ),
            if (_skck) ...[
              const SizedBox(height: AppSpace.s8),
              const IconInfoRow(
                icon: LucideIcons.fileCheck,
                text: 'Wajib SKCK',
              ),
            ],
            if (_skip) ...[
              const SizedBox(height: AppSpace.s8),
              const IconInfoRow(icon: LucideIcons.zap, text: 'Tanpa wawancara'),
            ],
          ],
        ),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final last = _step == 3;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Buat lowongan'),
          leading: AppIconButton(
            icon: LucideIcons.arrowLeft,
            label: 'Kembali',
            onPressed: _onBack,
          ),
        ),
        scrollable: true,
        glow: true,
        body: _loadingDraft
            ? const ListSkeleton(count: 2)
            : _loadError != null
            ? ApiErrorView(error: _loadError!, onRetry: _loadDraft)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepProgress(
                    current: _step + 1,
                    total: _steps.length,
                    title: _steps[_step],
                  ),
                  const SizedBox(height: AppSpace.s16),
                  if (actionError != null) ActionErrorBox(error: actionError!),
                  ..._stepBody(),
                  const SizedBox(height: AppSpace.s24),
                  AppButton(
                    key: K.wizardNext,
                    label: last ? 'Lanjut ke pembayaran' : 'Lanjut',
                    large: true,
                    loading: busy,
                    onPressed: canAct ? _next : null,
                  ),
                  if (_step > 0) ...[
                    const SizedBox(height: AppSpace.s8),
                    AppButton(
                      key: K.wizardBack,
                      label: 'Kembali',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => setState(() => _step--),
                    ),
                  ],
                  if (_step >= 2 && _savable) ...[
                    const SizedBox(height: AppSpace.s8),
                    AppButton(
                      key: K.wizardSaveDraft,
                      label: 'Simpan draf',
                      variant: AppButtonVariant.text,
                      onPressed: canAct ? _saveTapped : null,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
