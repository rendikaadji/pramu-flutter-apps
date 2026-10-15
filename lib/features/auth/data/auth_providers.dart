import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/auth/data/api_auth_repository.dart';
import 'package:pramu_apps/features/auth/data/mock_auth_repository.dart';
import 'package:pramu_apps/features/auth/domain/auth_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => Env.useMock
      ? MockAuthRepository(ref.watch(mockBackendProvider))
      : ApiAuthRepository(ref.watch(apiClientProvider)),
);
