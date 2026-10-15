import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/verification/data/api_verification_repository.dart';
import 'package:pramu_apps/features/verification/data/mock_verification_repository.dart';
import 'package:pramu_apps/features/verification/domain/verification_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => Env.useMock
      ? MockVerificationRepository(ref.watch(mockBackendProvider))
      : ApiVerificationRepository(ref.watch(apiClientProvider)),
);
