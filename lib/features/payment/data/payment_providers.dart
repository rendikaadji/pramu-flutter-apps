import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/payment/data/api_payment_repository.dart';
import 'package:pramu_apps/features/payment/data/mock_payment_repository.dart';
import 'package:pramu_apps/features/payment/domain/payment_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => Env.useMock
      ? MockPaymentRepository(ref.watch(mockBackendProvider))
      : ApiPaymentRepository(ref.watch(apiClientProvider)),
);
