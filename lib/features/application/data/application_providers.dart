import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/application/data/api_application_repository.dart';
import 'package:pramu_apps/features/application/data/mock_application_repository.dart';
import 'package:pramu_apps/features/application/domain/application_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => Env.useMock
      ? MockApplicationRepository(ref.watch(mockBackendProvider))
      : ApiApplicationRepository(ref.watch(apiClientProvider)),
);
