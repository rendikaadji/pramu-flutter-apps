import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/booking/data/api_booking_repository.dart';
import 'package:pramu_apps/features/booking/data/mock_booking_repository.dart';
import 'package:pramu_apps/features/booking/domain/booking_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => Env.useMock
      ? MockBookingRepository(ref.watch(mockBackendProvider))
      : ApiBookingRepository(ref.watch(apiClientProvider)),
);
