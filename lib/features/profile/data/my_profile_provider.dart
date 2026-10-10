import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/profile/data/profile_providers.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';

/// Profil asisten milik pengguna aktif (null = belum dibuat). Dibaca M-40 dan beranda (M-21).
final myProfileProvider = FutureProvider.autoDispose<AssistantProfile?>((ref) {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  return ref.watch(profileRepositoryProvider).myProfile();
}, retry: (_, _) => null);
