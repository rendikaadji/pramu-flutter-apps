import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/job/job.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/daftar_aksi.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';

/// Tab Job: majikan melihat job miliknya (S-07), pekerja mencari job (S-08).
class TabJobScreen extends ConsumerWidget {
  const TabJobScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(peranAktifProvider) == Peran.majikan
      ? const _JobSaya()
      : const _CariJob();
}

class _JobSaya extends ConsumerWidget {
  const _JobSaya();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(jobSayaProvider);
    return AppScaffold(
      title: 'Job saya',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/job/buat'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Buat job'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(jobSayaProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            Muat(
              nilai: daftar,
              onUlangi: () => ref.invalidate(jobSayaProvider),
              isi: (h) => h.items.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada job',
                      message: 'Buat job untuk melihat pekerja yang cocok.',
                    )
                  : Column(
                      children: [
                        for (final j in h.items) ...[
                          AppCard(
                            onTap: () => context.push('/job/${j.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${j.judul} · ${labelStatusJob[j.status] ?? j.status}',
                                  style: context.text.h3,
                                ),
                                Text(
                                  '${j.kisaran} · ${formatDateTime(j.mulaiKerja)}',
                                  style: context.text.bodySm,
                                ),
                                if (j.jumlahAjuanMenunggu > 0)
                                  Text(
                                    '${j.jumlahAjuanMenunggu} ajuan menunggu',
                                    style: context.text.bodySm.copyWith(
                                      color: context.tokens.warning,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.s12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CariJob extends ConsumerStatefulWidget {
  const _CariJob();

  @override
  ConsumerState<_CariJob> createState() => _CariJobState();
}

class _CariJobState extends ConsumerState<_CariJob> {
  String? _proses;
  final _galat = <String, String>{};

  // Pekerja mengajukan diri ke job (PRD §12); harga dan batas waktu dihitung server.
  Future<void> _ajukan(String jobId) async {
    setState(() => _proses = jobId);
    try {
      final b =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/booking',
                    data: {'job_id': jobId},
                    options: ApiClient.idempotent(newIdempotencyKey()),
                  )
              as Json;
      if (mounted) context.push('/booking/${b['id']}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat[jobId] = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daftar = ref.watch(cariJobProvider);
    return AppScaffold(
      title: 'Cari job',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(cariJobProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            Muat(
              nilai: daftar,
              onUlangi: () => ref.invalidate(cariJobProvider),
              isi: (h) => h.items.isEmpty
                  ? const EmptyState(
                      title: 'Belum ada job',
                      message: 'Belum ada job yang cocok dengan jenis pekerjaan dan kisaran upahmu.',
                    )
                  : Column(
                      children: [
                        for (final j in h.items) ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(j.judul, style: context.text.h3),
                                Text(
                                  '${j.labelTipe} · ${j.kecamatan} · ${j.kelompokJarak} km',
                                  style: context.text.bodySm,
                                ),
                                Text(
                                  '${formatDateTime(j.mulaiKerja)} · Upah ${j.upah}',
                                  style: context.text.bodySm,
                                ),
                                if (j.kamuMembayar == true)
                                  Text(
                                    'Biaya admin kamu yang menanggung.',
                                    style: context.text.bodySm,
                                  ),
                                const SizedBox(height: AppSpace.s8),
                                ProfilBaris(profil: j.majikan),
                                const SizedBox(height: AppSpace.s8),
                                AppButton(
                                  label: 'Ajukan',
                                  loading: _proses == j.id,
                                  onPressed: _proses == null
                                      ? () => _ajukan(j.id)
                                      : null,
                                ),
                                if (_galat[j.id] != null)
                                  FieldErrorText(_galat[j.id]!),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.s12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail job majikan: ringkasan, tutup, dan kandidat yang cocok dengan tombol Ajukan (S-08 majikan).
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  String? _proses;
  final _galat = <String, String>{};

  Future<void> _ajukan(String profilId) async {
    setState(() => _proses = profilId);
    try {
      final b =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/booking',
                    data: {'job_id': widget.id, 'pekerja_profil_id': profilId},
                    options: ApiClient.idempotent(newIdempotencyKey()),
                  )
              as Json;
      if (mounted) context.push('/booking/${b['id']}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat[profilId] = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _proses = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(jobProvider(widget.id));
    return AppScaffold(
      title: job.value?.judul ?? 'Job',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Muat(
            nilai: job,
            onUlangi: () => ref.invalidate(jobProvider(widget.id)),
            isi: (j) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${labelStatusJob[j.status] ?? j.status} · Kisaran ${j.kisaran}',
                  style: context.text.body,
                ),
                Text(formatDateTime(j.mulaiKerja), style: context.text.bodySm),
                if (j.deskripsi != null) ...[
                  const SizedBox(height: AppSpace.s8),
                  Text(j.deskripsi!, style: context.text.body),
                ],
                if (j.jumlahAjuanMenunggu > 0)
                  Text(
                    '${j.jumlahAjuanMenunggu} ajuan menunggu',
                    style: context.text.bodySm,
                  ),
                const SizedBox(height: AppSpace.s16),
                DaftarAksi(
                  aksi: Aksi(
                    tersedia: [
                      for (final a in j.aksi.tersedia)
                        if (a == 'TUTUP') a,
                    ],
                    akibat: j.aksi.akibat,
                  ),
                  jalankan: (_) async {
                    await ref
                        .read(apiClientProvider)
                        .post('/job/${j.id}/tutup');
                    ref.invalidate(jobProvider(widget.id));
                    ref.invalidate(jobSayaProvider);
                  },
                ),
                if (j.status == 'TERBUKA') ...[
                  const SizedBox(height: AppSpace.s16),
                  Text('Pekerja yang cocok', style: context.text.h2),
                  Text(
                    'Pekerja punya 24 jam untuk menyetujui. Upah diambil dari irisan kisaran kalian.',
                    style: context.text.bodySm,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  _Kandidat(
                    id: j.id,
                    proses: _proses,
                    galat: _galat,
                    ajukan: _ajukan,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kandidat extends ConsumerWidget {
  const _Kandidat({
    required this.id,
    required this.proses,
    required this.galat,
    required this.ajukan,
  });

  final String id;
  final String? proses;
  final Map<String, String> galat;
  final void Function(String profilId) ajukan;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Muat(
    nilai: ref.watch(kandidatProvider(id)),
    onUlangi: () => ref.invalidate(kandidatProvider(id)),
    isi: (h) => h.items.isEmpty
        ? Text('Belum ada pekerja yang cocok.', style: context.text.bodySm)
        : Column(
            children: [
              if (h.extra['sisa_ajuan_hari_ini'] != null)
                Text(
                  'Sisa ajuan hari ini: ${h.extra['sisa_ajuan_hari_ini']}',
                  style: context.text.caption,
                ),
              for (final k in h.items) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfilBaris(profil: k.profil),
                      const SizedBox(height: AppSpace.s8),
                      Text(
                        '${k.kelompokJarak} km · Upah ${k.upah}',
                        style: context.text.bodySm,
                      ),
                      const SizedBox(height: AppSpace.s8),
                      AppButton(
                        label: 'Ajukan',
                        loading: proses == k.profil.id,
                        onPressed: proses == null
                            ? () => ajukan(k.profil.id)
                            : null,
                      ),
                      if (galat[k.profil.id] != null)
                        FieldErrorText(galat[k.profil.id]!),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s12),
              ],
            ],
          ),
  );
}

/// S-06 Buat job. Kisaran, kuota, dan wilayah pilot diperiksa server; galat kolom tampil di kolomnya.
class BuatJobScreen extends ConsumerStatefulWidget {
  const BuatJobScreen({super.key});

  @override
  ConsumerState<BuatJobScreen> createState() => _BuatJobScreenState();
}

class _BuatJobScreenState extends ConsumerState<BuatJobScreen> {
  final _kunci = newIdempotencyKey();
  final _nama = TextEditingController();
  final _titik = TextEditingController();
  final _jam = TextEditingController();
  final _deskripsi = TextEditingController();
  Kategori? _kategori;
  DateTime? _mulai; // jam dinding WIB yang dipilih
  String _pola = 'HARIAN';
  String _pembayar = 'MAJIKAN';
  bool _proses = false;
  ApiException? _galat;

  @override
  void dispose() {
    for (final c in [_nama, _titik, _jam, _deskripsi]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihWaktu() async {
    final besok = toWib(DateTime.now()).add(const Duration(days: 1));
    final tgl = await showDatePicker(
      context: context,
      initialDate: _mulai ?? besok,
      firstDate: toWib(DateTime.now()),
      lastDate: besok.add(const Duration(days: 90)),
    );
    if (tgl == null || !mounted) return;
    final jam = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (jam == null) return;
    setState(
      () =>
          _mulai = DateTime(tgl.year, tgl.month, tgl.day, jam.hour, jam.minute),
    );
  }

  Future<void> _terbit() async {
    final k = _kategori;
    final m = _mulai;
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      final job =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/job',
                    data: {
                      'kategori_id': k?.id,
                      'titik_awal': int.tryParse(
                        _titik.text.replaceAll(RegExp(r'\D'), ''),
                      ),
                      'mulai_kerja': m == null
                          ? null
                          : toApiTime(
                              fromWib(m.year, m.month, m.day, m.hour, m.minute),
                            ),
                      if (k?.namaBebas ?? false) 'nama_pekerjaan': _nama.text,
                      if (k?.periodik ?? false) ...{
                        'pola_kerja': _pola,
                        'biaya_admin_ditanggung': _pembayar,
                      },
                      if (k != null && !k.periodik && _jam.text.isNotEmpty)
                        'perkiraan_jam': int.tryParse(_jam.text),
                      if (_deskripsi.text.isNotEmpty)
                        'deskripsi': _deskripsi.text,
                      'lokasi': null,
                    },
                    options: ApiClient.idempotent(_kunci),
                  )
              as Json;
      ref.invalidate(jobSayaProvider);
      if (mounted) context.pushReplacement('/job/${job['id']}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = e);
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  String? _kolom(String k) => _galat?.fields[k]?.first;

  @override
  Widget build(BuildContext context) {
    final kategori = ref.watch(kategoriProvider);
    final k = _kategori;
    return AppScaffold(
      title: 'Buat job',
      scrollable: true,
      body: Muat(
        nilai: kategori,
        onUlangi: () => ref.invalidate(kategoriProvider),
        isi: (daftar) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Kategori>(
              initialValue: k,
              decoration: InputDecoration(
                labelText: 'Jenis pekerjaan',
                errorText: _kolom('kategori_id'),
              ),
              items: [
                for (final tipe in ['INSIDENTAL', 'PERIODIK'])
                  for (final x in daftar.where((x) => x.tipe == tipe))
                    DropdownMenuItem(
                      value: x,
                      child: Text(
                        '${x.nama} · ${tipe == 'PERIODIK' ? 'Rutin' : 'Sekali datang'}',
                      ),
                    ),
              ],
              onChanged: (v) => setState(() => _kategori = v),
            ),
            if (k?.namaBebas ?? false) ...[
              const SizedBox(height: AppSpace.s12),
              AppTextField(
                label: 'Nama pekerjaan',
                controller: _nama,
                maxLength: 40,
                errorText: _kolom('nama_pekerjaan'),
              ),
            ],
            const SizedBox(height: AppSpace.s12),
            AppTextField(
              label: 'Upah awal',
              prefixText: 'Rp',
              controller: _titik,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              helper: k == null
                  ? null
                  : 'Kelipatan ${k.kelipatanTitik}. Kisaran dihitung server.',
              errorText: _kolom('titik_awal'),
            ),
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: _mulai == null
                  ? 'Pilih waktu mulai'
                  : 'Mulai: ${_mulai!.day}/${_mulai!.month}/${_mulai!.year} ${_mulai!.hour.toString().padLeft(2, '0')}.${_mulai!.minute.toString().padLeft(2, '0')} WIB',
              variant: AppButtonVariant.secondary,
              icon: LucideIcons.calendar,
              onPressed: _pilihWaktu,
            ),
            if (_kolom('mulai_kerja') != null)
              FieldErrorText(_kolom('mulai_kerja')!),
            if (k?.periodik ?? false) ...[
              const SizedBox(height: AppSpace.s12),
              DropdownButtonFormField<String>(
                initialValue: _pola,
                decoration: InputDecoration(
                  labelText: 'Pola kerja',
                  errorText: _kolom('pola_kerja'),
                ),
                items: const [
                  DropdownMenuItem(value: 'HARIAN', child: Text('Harian')),
                  DropdownMenuItem(value: 'MENGINAP', child: Text('Menginap')),
                ],
                onChanged: (v) => setState(() => _pola = v!),
              ),
              const SizedBox(height: AppSpace.s12),
              DropdownButtonFormField<String>(
                initialValue: _pembayar,
                decoration: InputDecoration(
                  labelText: 'Biaya admin ditanggung',
                  errorText: _kolom('biaya_admin_ditanggung'),
                ),
                items: const [
                  DropdownMenuItem(value: 'MAJIKAN', child: Text('Saya')),
                  DropdownMenuItem(value: 'PEKERJA', child: Text('Pekerja')),
                ],
                onChanged: (v) => setState(() => _pembayar = v!),
              ),
            ] else if (k != null) ...[
              const SizedBox(height: AppSpace.s12),
              AppTextField(
                label: 'Perkiraan jam kerja',
                controller: _jam,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _kolom('perkiraan_jam'),
              ),
            ],
            const SizedBox(height: AppSpace.s12),
            AppTextField(
              label: 'Catatan untuk pekerja',
              controller: _deskripsi,
              maxLength: 500,
              errorText: _kolom('deskripsi'),
            ),
            Text(
              'Lokasi pekerjaan: rumahmu (dari profil).',
              style: context.text.caption,
            ),
            if (_kolom('lokasi') != null) FieldErrorText(_kolom('lokasi')!),
            if (_galat != null && _galat!.fields.isEmpty)
              FieldErrorText(pesanGalat(_galat!)),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Terbitkan job',
              expand: true,
              loading: _proses,
              onPressed: _proses ? null : _terbit,
            ),
          ],
        ),
      ),
    );
  }
}
