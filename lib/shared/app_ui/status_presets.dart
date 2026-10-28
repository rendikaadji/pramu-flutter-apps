import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_tokens.dart';
import 'status_chip.dart';

enum StatusDomain {
  period,
  booking,
  application,
  listing,
  interview,
  verification,
}

typedef _P = (String, String?, StatusTone, IconData?);

// Label per peran (Pencari, Asisten?) - null = sama. Sumber: Brief §9.
const Map<StatusDomain, Map<String, _P>> _presets = {
  StatusDomain.period: {
    'scheduled': ('Terjadwal', null, StatusTone.neutral, LucideIcons.calendar),
    'in_progress': ('Sedang berjalan', null, StatusTone.info, null),
    'completed': ('Selesai', null, StatusTone.success, null),
    'cancelled': ('Dibatalkan', null, StatusTone.neutral, LucideIcons.ban),
  },
  StatusDomain.booking: {
    'active': ('Berjalan', null, StatusTone.info, null),
    'completed': ('Selesai', null, StatusTone.success, null),
    'cancelled': ('Dibatalkan', null, StatusTone.neutral, LucideIcons.ban),
  },
  StatusDomain.application: {
    'pending': ('Dilamar', null, StatusTone.neutral, null),
    'shortlisted': ('Masuk daftar pendek', null, StatusTone.info, null),
    'interview_scheduled': (
      'Wawancara dijadwalkan',
      null,
      StatusTone.info,
      LucideIcons.calendar,
    ),
    'interviewed': ('Sudah diwawancara', null, StatusTone.info, null),
    'accepted': ('Diterima', null, StatusTone.success, null),
    'rejected': ('Tidak dipilih', null, StatusTone.neutral, LucideIcons.ban),
    'withdrawn': ('Ditarik', null, StatusTone.neutral, LucideIcons.ban),
  },
  StatusDomain.listing: {
    'draft': ('Draf', null, StatusTone.neutral, null),
    'awaiting_payment': ('Menunggu pembayaran', null, StatusTone.warning, null),
    'open': ('Tayang', null, StatusTone.success, null),
    'filled': ('Terisi', null, StatusTone.info, null),
    'closed': ('Ditutup', null, StatusTone.neutral, LucideIcons.ban),
    'expired': ('Berakhir', null, StatusTone.neutral, null),
  },
  StatusDomain.interview: {
    'proposed': ('Menunggu konfirmasi', null, StatusTone.warning, null),
    'confirmed': ('Terjadwal', null, StatusTone.info, LucideIcons.calendar),
    'done': ('Selesai', null, StatusTone.success, null),
    'cancelled': ('Dibatalkan', null, StatusTone.neutral, LucideIcons.ban),
    'no_show': ('Tidak hadir', null, StatusTone.danger, null),
  },
  StatusDomain.verification: {
    'pending': ('Menunggu tinjauan', null, StatusTone.warning, null),
    'verified': (
      'Terverifikasi',
      null,
      StatusTone.success,
      LucideIcons.shieldCheck,
    ),
    'rejected': ('Ditolak', null, StatusTone.danger, null),
  },
};

({String label, StatusTone tone, IconData? icon}) statusPreset(
  StatusDomain domain,
  String code,
  AppRole role,
) {
  final p = _presets[domain]?[code];
  if (p == null) return (label: code, tone: StatusTone.neutral, icon: null);
  final label = role == AppRole.assistant ? (p.$2 ?? p.$1) : p.$1;
  return (label: label, tone: p.$3, icon: p.$4);
}
