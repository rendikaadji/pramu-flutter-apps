import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_ui.dart';

/// Katalog visual semua komponen app_ui, terang/gelap lewat saklar. Untuk review
/// manual dan golden test. Tidak terdaftar di router.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key, this.initialDark = false});

  final bool initialDark;

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  late bool _dark = widget.initialDark;
  AppRole _role = AppRole.seeker;
  int _nav = 0;
  int _rating = 3;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? AppTheme.dark() : AppTheme.light(),
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    final t = context.tokens;
    return AppScaffold(
      title: 'Galeri komponen',
      actions: [
        Switch(value: _dark, onChanged: (v) => setState(() => _dark = v)),
        Padding(
          padding: const EdgeInsets.only(right: AppSpace.s16),
          child: Center(child: Text(_dark ? 'Gelap' : 'Terang')),
        ),
      ],
      scrollable: true,
      banner: const OfflineBanner(updatedAt: 'diperbarui 14.02'),
      bottomNavigationBar: AppBottomNav(
        role: _role,
        index: _nav,
        onTap: (i) => setState(() => _nav = i),
        items: [
          const AppNavItem(icon: LucideIcons.house, label: 'Beranda'),
          const AppNavItem(icon: LucideIcons.search, label: 'Cari'),
          const AppNavItem(icon: LucideIcons.briefcase, label: 'Pekerjaan'),
          const AppNavItem(
            icon: LucideIcons.messageSquare,
            label: 'Pesan',
            badgeCount: 3,
          ),
          if (_role == AppRole.assistant)
            const AppNavItem(icon: LucideIcons.wallet, label: 'Dompet'),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Warna'),
          _Swatches(t),
          const SectionHeader('Tipografi'),
          Text('Display 32', style: context.text.display),
          Text('Judul layar h1', style: context.text.h1),
          Text('Judul seksi h2', style: context.text.h2),
          Text('Judul kartu h3', style: context.text.h3),
          Text('Isi default 16/24', style: context.text.body),
          Text('Metadata body-sm 14/20', style: context.text.bodySm),
          Text('Caption 12/16', style: context.text.caption),
          const MoneyText('Rp1.250.000', size: MoneySize.hero),
          const SectionHeader('Tombol'),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              AppButton(label: 'Simpan', onPressed: () {}, expand: false),
              AppButton(
                label: 'Sekunder',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
                expand: false,
              ),
              AppButton(
                label: 'Tonal',
                variant: AppButtonVariant.tonal,
                onPressed: () {},
                expand: false,
              ),
              AppButton(
                label: 'Batalkan',
                variant: AppButtonVariant.danger,
                icon: LucideIcons.ban,
                onPressed: () {},
                expand: false,
              ),
              AppButton(
                label: 'Teks',
                variant: AppButtonVariant.text,
                onPressed: () {},
                expand: false,
              ),
              const AppButton(
                label: 'Nonaktif',
                onPressed: null,
                expand: false,
              ),
              AppIconButton(
                icon: LucideIcons.bell,
                label: 'Notifikasi',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            label: _loading ? 'Mengirim' : 'Bayar Rp1.050.000',
            large: true,
            loading: _loading,
            onPressed: () {
              setState(() => _loading = true);
              Future<void>.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _loading = false);
              });
            },
          ),
          const SectionHeader('Form'),
          const AppTextField(
            label: 'Nomor HP',
            hint: '812 3456 7890',
            prefixText: '+62',
            keyboardType: TextInputType.phone,
            helper: 'Kami kirim kode lewat SMS.',
          ),
          const SizedBox(height: AppSpace.s16),
          const AppTextField(
            label: 'Nomor KTP',
            obscure: true,
            keyboardType: TextInputType.number,
            maxLength: 16,
            errorText: 'Nomor KTP harus 16 digit.',
          ),
          const SizedBox(height: AppSpace.s16),
          const AppTextField(
            label: 'Upah per bulan',
            prefixText: 'Rp',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpace.s16),
          const Text('Kode OTP'),
          const SizedBox(height: AppSpace.s8),
          const OtpInput(autofocus: false),
          const SizedBox(height: AppSpace.s16),
          const Text('Penilaian'),
          RatingStars(
            value: _rating.toDouble(),
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SectionHeader('Status & kepercayaan'),
          const Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              StatusChip(label: 'Netral', tone: StatusTone.neutral),
              StatusChip(label: 'Info', tone: StatusTone.info),
              StatusChip(label: 'Berhasil', tone: StatusTone.success),
              StatusChip(label: 'Perhatian', tone: StatusTone.warning),
              StatusChip(label: 'Gagal', tone: StatusTone.danger),
              StatusChip(label: 'Aksen', tone: StatusTone.accent),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              StatusChip.of(StatusDomain.period, 'paid'),
              StatusChip.of(
                StatusDomain.period,
                'awaiting_payment',
                role: AppRole.assistant,
              ),
              StatusChip.of(StatusDomain.listing, 'open'),
              StatusChip.of(StatusDomain.payout, 'failed'),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          const Wrap(
            spacing: AppSpace.s16,
            runSpacing: AppSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VerificationSeal(size: SealSize.sm),
              VerificationSeal(),
              VerificationSeal(state: SealState.pending),
              VerificationSeal(state: SealState.rejected),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          const TrustCard(
            skckVerified: true,
            rating: 4.5,
            reviewCount: 12,
            completedJobs: 8,
            since: 'Mar 2026',
          ),
          const SectionHeader('Uang & period'),
          const FeeBreakdown(
            rows: [
              FeeRow('Gaji periode 1', 'Rp1.000.000'),
              FeeRow('Biaya layanan (5%)', 'Rp50.000'),
              FeeRow('Total', 'Rp1.050.000', total: true),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          const LedgerTimeline(
            entries: [
              LedgerEntry(
                title: 'Periode 1',
                label: 'Selesai',
                tone: StatusTone.success,
                date: '1 - 30 Sep 2026',
                amount: 'Rp1.000.000',
              ),
              LedgerEntry(
                title: 'Periode 2',
                label: 'Dana ditahan aman',
                tone: StatusTone.info,
                date: '1 - 31 Okt 2026',
                amount: 'Rp1.000.000',
                icon: LucideIcons.shieldCheck,
              ),
              LedgerEntry(
                title: 'Periode 3',
                label: 'Menunggu pembayaran',
                tone: StatusTone.warning,
                date: '1 - 30 Nov 2026',
                amount: 'Rp1.000.000',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          const LedgerMini(
            tones: [
              StatusTone.success,
              StatusTone.info,
              StatusTone.warning,
              StatusTone.neutral,
            ],
          ),
          const SectionHeader('Kartu & peran'),
          NextStepCard(
            role: _role,
            title: '3 pelamar baru',
            message: 'Tinjau profil kepercayaan mereka.',
            onTap: () {},
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              RoleChip(
                role: _role,
                onTap: () => showRoleSwitchSheet(
                  context,
                  current: _role,
                  onSelect: (r) => setState(() {
                    _role = r;
                    _nav = 0;
                  }),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              const AvatarImage(name: 'Siti Rahma'),
              const SizedBox(width: AppSpace.s8),
              const AvatarImage(name: 'Joko', size: 48),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          const PrivacyNote(
            'Nomor disembunyikan sampai pembayaran dilakukan, demi keamanan Anda.',
          ),
          const SectionHeader('Alur'),
          const StepProgress(current: 2, total: 4, title: 'Deskripsi'),
          const SizedBox(height: AppSpace.s16),
          const Row(
            children: [
              AppSkeleton.box(48, radius: 24),
              SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.line(),
                    SizedBox(height: AppSpace.s8),
                    AppSkeleton.line(width: 120),
                  ],
                ),
              ),
            ],
          ),
          const SectionHeader('Status layar'),
          const EmptyState(
            icon: LucideIcons.search,
            title: 'Belum ada asisten yang cocok',
            message: 'Coba perluas kota atau rentang tarif.',
            actionLabel: 'Reset filter',
          ),
          ErrorState(code: 'SRV_500', onRetry: () {}),
          const SizedBox(height: AppSpace.s12),
          PermissionRationaleCard(
            icon: LucideIcons.camera,
            title: 'Izin kamera dimatikan',
            message: 'Aktifkan di Pengaturan, atau pilih foto dari galeri.',
            primaryLabel: 'Buka Pengaturan',
            onPrimary: () {},
            secondaryLabel: 'Pilih dari galeri',
            onSecondary: () {},
            denied: true,
          ),
          const SectionHeader('Overlay'),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              AppButton(
                label: 'Dialog',
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () => ConfirmDialog.show(
                  context,
                  title: 'Tarik lamaran ini?',
                  message:
                      'Anda tidak dapat melamar ulang pekerjaan yang sama.',
                  confirmLabel: 'Tarik lamaran',
                  destructive: true,
                ),
              ),
              AppButton(
                label: 'Snackbar',
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () => AppSnack.show(
                  context,
                  'Sekarang sebagai Asisten',
                  success: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.t);
  final AppTokens t;

  @override
  Widget build(BuildContext context) {
    final items = <(String, Color)>[
      ('canvas', t.canvas),
      ('surface', t.surface),
      ('sunken', t.sunken),
      ('primary', t.primary),
      ('primary c', t.primaryContainer),
      ('accent', t.accent),
      ('accent c', t.accentContainer),
      ('success', t.success),
      ('warning', t.warning),
      ('danger', t.danger),
      ('border', t.borderStrong),
      ('text', t.textPrimary),
    ];
    return Wrap(
      spacing: AppSpace.s8,
      runSpacing: AppSpace.s8,
      children: [
        for (final (name, c) in items)
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(color: t.borderStrong),
                ),
              ),
              Text(name, style: context.text.caption),
            ],
          ),
      ],
    );
  }
}
