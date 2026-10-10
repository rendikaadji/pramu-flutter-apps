import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/interview/data/api_interview_repository.dart';
import 'package:pramu_apps/features/interview/data/mock_interview_repository.dart';
import 'package:pramu_apps/features/interview/domain/interview_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final interviewRepositoryProvider = Provider<InterviewRepository>(
  (ref) => Env.useMock
      ? MockInterviewRepository(ref.watch(mockBackendProvider))
      : ApiInterviewRepository(ref.watch(apiClientProvider)),
);
