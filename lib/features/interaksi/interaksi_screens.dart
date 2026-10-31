import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/ids.dart';
import 'package:pramu_apps/core/models/pramu.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/muat.dart';
import 'package:pramu_apps/shared/profil_baris.dart';

final _percakapanProvider = FutureProvider.autoDispose<Paged<Json>>(
  (ref) => ref.watch(apiClientProvider).getPage('/percakapan', (j) => j),
);

final _pesanProvider = FutureProvider.autoDispose.family<Paged<Json>, String>(
  (ref, id) =>
      ref.watch(apiClientProvider).getPage('/percakapan/$id/pesan', (j) => j),
);

final _notifikasiProvider = FutureProvider.autoDispose<Paged<Json>>(
  (ref) => ref.watch(apiClientProvider).getPage('/notifikasi', (j) => j),
);

/// Daftar percakapan (S-16).
class PercakapanDaftarScreen extends ConsumerWidget {
  const PercakapanDaftarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Chat',
    body: ListView(
      padding: const EdgeInsets.all(AppSpace.s16),
      children: [
        Muat(
          nilai: ref.watch(_percakapanProvider),
          onUlangi: () => ref.invalidate(_percakapanProvider),
          isi: (h) => h.items.isEmpty
              ? const EmptyState(
                  title: 'Belum ada percakapan',
                  message: 'Chat terbuka setelah ada ajuan.',
                )
              : Column(
                  children: [
                    for (final c in h.items) ...[
                      AppCard(
                        onTap: () => context.push('/percakapan/${c['id']}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfilBaris(
                              profil: RingkasanProfil.fromJson(
                                c['pihak_lain'] as Json,
                              ),
                            ),
                            const SizedBox(height: AppSpace.s8),
                            Text(
                              c['judul_job'] as String,
                              style: context.text.label,
                            ),
                            if (c['pesan_terakhir'] != null)
                              Text(
                                c['pesan_terakhir'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySm,
                              ),
                            if ((c['belum_dibaca'] as num? ?? 0) > 0)
                              Text(
                                '${c['belum_dibaca']} belum dibaca',
                                style: context.text.caption.copyWith(
                                  color: context.tokens.primary,
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
  );
}

/// Satu percakapan. Kontak di pesan disamarkan server sebelum disimpan (PRD §20).
class PercakapanScreen extends ConsumerStatefulWidget {
  const PercakapanScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PercakapanScreen> createState() => _PercakapanScreenState();
}

class _PercakapanScreenState extends ConsumerState<PercakapanScreen> {
  final _tulis = TextEditingController();
  bool _proses = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    // Tandai dibaca saat dibuka; gagal tidak mengganggu membaca.
    ref
        .read(apiClientProvider)
        .post('/percakapan/${widget.id}/baca')
        .catchError((_) => null);
  }

  @override
  void dispose() {
    _tulis.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (_tulis.text.trim().isEmpty) return;
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/percakapan/${widget.id}/pesan',
            data: {'isi': _tulis.text},
            options: ApiClient.idempotent(newIdempotencyKey()),
          );
      _tulis.clear();
      ref.invalidate(_pesanProvider(widget.id));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _galat = e.fields['isi']?.first ?? pesanGalat(e));
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppScaffold(
      title: 'Chat',
      padded: false,
      body: Column(
        children: [
          Expanded(
            child: Muat(
              nilai: ref.watch(_pesanProvider(widget.id)),
              onUlangi: () => ref.invalidate(_pesanProvider(widget.id)),
              isi: (h) => ListView(
                reverse: true, // server mengirim terbaru dulu
                padding: const EdgeInsets.all(AppSpace.s16),
                children: [
                  for (final m in h.items)
                    Align(
                      alignment: m['dari_saya'] == true
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpace.s8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s12,
                          vertical: AppSpace.s8,
                        ),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: m['dari_saya'] == true
                              ? t.primaryContainer
                              : t.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['isi'] as String, style: context.text.body),
                            Text(
                              [
                                formatTime(
                                  parseApiTime(m['dibuat_at'] as String),
                                ),
                                if (m['ada_samaran'] == true)
                                  'Kontak disamarkan',
                              ].join(' · '),
                              style: context.text.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Tulis pesan',
                          controller: _tulis,
                          maxLength: 1000,
                          onSubmitted: (_) => _kirim(),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s8),
                      AppButton(
                        label: 'Kirim',
                        expand: false,
                        loading: _proses,
                        onPressed: _proses ? null : _kirim,
                      ),
                    ],
                  ),
                  if (_galat != null) FieldErrorText(_galat!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// S-19 Notifikasi. Mengetuk membuka `tujuan` dari server dengan peran yang dimaksud.
class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  Future<void> _buka(BuildContext context, WidgetRef ref, Json n) async {
    if (n['dibaca_at'] == null) {
      ref
          .read(apiClientProvider)
          .post('/notifikasi/${n['id']}/baca')
          .catchError((_) => null);
    }
    final peran = n['peran'] as String?;
    final akun = ref.read(sessionProvider).value;
    if (peran != null && (akun?.peran.contains(peran) ?? false)) {
      ref.read(peranAktifProvider.notifier).pilih(peran);
    }
    if (context.mounted) context.push(n['tujuan'] as String? ?? '/beranda');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(_notifikasiProvider);
    final belum = daftar.value?.extra['belum_dibaca'] as num? ?? 0;
    return AppScaffold(
      title: 'Notifikasi',
      actions: [
        if (belum > 0)
          TextButton(
            onPressed: () async {
              await ref.read(apiClientProvider).post('/notifikasi/baca-semua');
              ref.invalidate(_notifikasiProvider);
            },
            child: const Text('Tandai semua dibaca'),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s16),
        children: [
          Muat(
            nilai: daftar,
            onUlangi: () => ref.invalidate(_notifikasiProvider),
            isi: (h) => h.items.isEmpty
                ? const EmptyState(
                    title: 'Belum ada notifikasi',
                    message:
                        'Kabar tentang ajuan dan pekerjaanmu tampil di sini.',
                  )
                : Column(
                    children: [
                      for (final n in h.items) ...[
                        AppCard(
                          onTap: () => _buka(context, ref, n),
                          borderColor: n['dibaca_at'] == null
                              ? context.tokens.primary
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['judul'] as String,
                                style: context.text.h3,
                              ),
                              Text(
                                n['isi'] as String,
                                style: context.text.bodySm,
                              ),
                              Text(
                                formatDateTime(
                                  parseApiTime(n['dibuat_at'] as String),
                                ),
                                style: context.text.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.s8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
