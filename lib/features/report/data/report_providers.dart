import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/report/data/api_report_repository.dart';
import 'package:pramu_apps/features/report/data/mock_report_repository.dart';
import 'package:pramu_apps/features/report/domain/report_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => Env.useMock
      ? MockReportRepository(ref.watch(mockBackendProvider))
      : ApiReportRepository(ref.watch(apiClientProvider)),
);
