import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/listing/presentation/widgets/assistant_card.dart';
import 'package:pramu_apps/features/profile/data/my_profile_provider.dart';
import 'package:pramu_apps/features/profile/data/profile_providers.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/features/profile/presentation/screens/assistant_profile_screen.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

// ponytail: daftar kategori tetap di klien; pindah ke endpoint bila server menyediakannya.
const profileCategories = [
  'Asisten Rumah Tangga',
  'Pengasuh Anak',
  'Perawat Lansia',
  'Juru Masak',
];

/// M-40 Edit profil asisten + meter kelengkapan + pratinjau.
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myProfileProvider);
    return AppScaffold(
      title: 'Profil asisten',
      glow: true,
      padded: false,
      body: AsyncBody<AssistantProfile?>(
        value: value,
        onRetry: () => ref.invalidate(myProfileProvider),
        data: (context, p) => _ProfileForm(initial: p),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({this.initial});
  final AssistantProfile? initial;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm>
    with ApiActionMixin {
  late final _city = TextEditingController(text: widget.initial?.city);
  late final _bio = TextEditingController(text: widget.initial?.bio);
  late final _years = TextEditingController(
    text: (widget.initial?.experienceYears ?? 0) > 0
        ? '${widget.initial!.experienceYears}'
        : '',
  );
  late final _rate = TextEditingController(
    text: (widget.initial?.rate ?? 0) > 0 ? '${widget.initial!.rate}' : '',
  );
  final _skillInput = TextEditingController();
  late final _categories = {...?widget.initial?.categories};
  late final _skills = [...?widget.initial?.skills];
  late PeriodUnit _unit = widget.initial?.unit ?? PeriodUnit.monthly;
  late bool _available = widget.initial?.available ?? true;
  Map<String, String> _local = {};

  @override
  void dispose() {
    for (final c in [_city, _bio, _years, _rate, _skillInput]) {
      c.dispose();
    }
    super.dispose();
  }

  AssistantProfile _draft() {
    final user = ref.read(sessionProvider).user;
    final i = widget.initial;
    return AssistantProfile(
      userId: i?.userId ?? user?.id ?? '',
      name: i?.name ?? user?.name ?? '',
      photoUrl: i?.photoUrl,
      categories: _categories.toList(),
      experienceYears: int.tryParse(_years.text) ?? 0,
      skills: _skills,
      rate: parseRupiah(_rate.text) ?? 0,
      unit: _unit,
      city: _city.text.trim(),
      available: _available,
      verified: i?.verified ?? false,
      ratingAvg: i?.ratingAvg ?? 0,
      ratingCount: i?.ratingCount ?? 0,
      completedJobs: i?.completedJobs ?? 0,
      bio: _bio.text.trim(),
    );
  }

  String? _err(String key) => _local[key] ?? fieldError(key);

  void _addSkill() {
    final s = _skillInput.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() {
      _skills.add(s);
      _skillInput.clear();
    });
  }

  Future<void> _save() async {
    final d = _draft();
    setState(() {
      actionError = null;
      _local = {
        if (d.categories.isEmpty) 'categories': 'Pilih minimal satu kategori',
        if (d.city.isEmpty) 'city': 'Kota wajib diisi',
      };
    });
    if (_local.isNotEmpty) return;
    final ok = await act(
      () => ref.read(profileRepositoryProvider).saveProfile(d),
      onConflict: () => ref.invalidate(myProfileProvider),
    );
    if (!ok || !mounted) return;
    ref.invalidate(myProfileProvider);
    ref.invalidate(assistantProfileProvider(d.userId));
    AppSnack.show(context, 'Profil disimpan', success: true);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final d = _draft();
    final meter = d.completeness;
    final verified = user?.verification.isVerified ?? false;
    final err = actionError;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s16),
      children: [
        if (err != null && err.isNetwork) const OfflineBanner(),
        if (!verified)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s16),
            child: AppCard(
              color: t.warningContainer,
              child: Text(
                'Profil tampil publik setelah akun Anda terverifikasi.',
                style: context.text.body,
              ),
            ),
          ),
        if (err != null) ActionErrorBox(error: err),
        Semantics(
          key: K.profileMeter,
          label: 'Kelengkapan profil $meter persen',
          excludeSemantics: true,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kelengkapan profil $meter%',
                        style: context.text.h3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s12),
                LinearProgressIndicator(
                  value: meter / 100,
                  minHeight: 8,
                  borderRadius: AppRadius.brXs,
                  color: meter >= 100 ? t.success : t.primary,
                  backgroundColor: t.borderSubtle,
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  meter >= 100
                      ? 'Profil lengkap, siap dilihat pencari.'
                      : 'Lengkapi data agar lebih mudah ditemukan pencari.',
                  style: context.text.bodySm.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        const SectionHeader('Data diri'),
        const SizedBox(height: AppSpace.s8),
        Text('Kategori', style: context.text.label),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s8,
          children: [
            for (final c in profileCategories)
              FilterChip(
                key: K.profileCategory(c),
                label: Text(c),
                selected: _categories.contains(c),
                onSelected: (on) => setState(() {
                  on ? _categories.add(c) : _categories.remove(c);
                  _local.remove('categories');
                }),
              ),
          ],
        ),
        if (_err('categories') != null) FieldErrorText(_err('categories')!),
        const SizedBox(height: AppSpace.s16),
        AppTextField(
          key: K.profileCity,
          label: 'Kota',
          prefixIcon: LucideIcons.mapPin,
          controller: _city,
          errorText: _err('city'),
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.s16),
        AppTextField(
          key: K.profileExperience,
          label: 'Pengalaman (tahun)',
          prefixIcon: LucideIcons.award,
          controller: _years,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 2,
          errorText: fieldError('experience_years'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextField(
                key: K.profileSkillInput,
                label: 'Keahlian',
                prefixIcon: LucideIcons.sparkles,
                hint: 'Mis. Memasak',
                controller: _skillInput,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            AppButton(
              label: 'Tambah',
              expand: false,
              variant: AppButtonVariant.secondary,
              onPressed: _addSkill,
            ),
          ],
        ),
        if (_skills.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: Wrap(
              spacing: AppSpace.s8,
              children: [
                for (final s in _skills)
                  InputChip(
                    label: Text(s),
                    onDeleted: () => setState(() => _skills.remove(s)),
                    deleteButtonTooltipMessage: 'Hapus $s',
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.s24),
        const SectionHeader('Tarif & ketersediaan'),
        const SizedBox(height: AppSpace.s8),
        AppTextField(
          key: K.profileRate,
          label: 'Tarif per periode',
          prefixText: 'Rp',
          controller: _rate,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: fieldError('rate'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.s12),
        Wrap(
          spacing: AppSpace.s8,
          children: [
            for (final u in [
              PeriodUnit.daily,
              PeriodUnit.weekly,
              PeriodUnit.monthly,
            ])
              ChoiceChip(
                label: Text(u.label),
                selected: _unit == u,
                onSelected: (_) => setState(() => _unit = u),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tersedia untuk bekerja', style: context.text.body),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        const SectionHeader('Tentang saya'),
        const SizedBox(height: AppSpace.s8),
        AppTextField(
          key: K.profileBio,
          label: 'Ceritakan pengalaman Anda',
          prefixIcon: LucideIcons.alignLeft,
          controller: _bio,
          maxLines: 4,
          maxLength: 300,
          errorText: fieldError('bio'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.s24),
        const SectionHeader('Begini pencari melihat Anda'),
        const SizedBox(height: AppSpace.s8),
        ExcludeSemantics(
          child: IgnorePointer(
            child: AssistantCard(profile: d, onTap: () {}),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        AppButton(
          key: K.profileSave,
          label: 'Simpan profil',
          large: true,
          loading: busy,
          onPressed: canAct ? _save : null,
        ),
      ],
    );
  }
}
