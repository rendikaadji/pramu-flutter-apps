import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/listing/data/api_listing_repository.dart';
import 'package:pramu_apps/features/listing/data/mock_listing_repository.dart';
import 'package:pramu_apps/features/listing/domain/listing_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => Env.useMock
      ? MockListingRepository(ref.watch(mockBackendProvider))
      : ApiListingRepository(ref.watch(apiClientProvider)),
);
