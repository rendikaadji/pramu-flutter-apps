import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/profile/data/api_profile_repository.dart';
import 'package:pramu_apps/features/profile/data/mock_profile_repository.dart';
import 'package:pramu_apps/features/profile/domain/profile_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => Env.useMock
      ? MockProfileRepository(ref.watch(mockBackendProvider))
      : ApiProfileRepository(ref.watch(apiClientProvider)),
);
